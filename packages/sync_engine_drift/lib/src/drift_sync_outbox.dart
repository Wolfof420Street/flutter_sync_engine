import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:sync_engine/sync_engine.dart';

import 'database.dart';

/// Durable outbox backed by the same Drift database as local sync storage.
///
/// Pending operations, retry metadata, and dead letters survive process
/// restarts. The queue uses the serialized entity payload captured by
/// [SyncEngine] so it can reconstruct transport-ready operations after a
/// restart.
class DriftSyncOutbox implements SyncOperationQueue {
  DriftSyncOutbox._({
    required SyncDriftDatabase database,
    required List<_StoredOutboxOperation> pending,
    required List<SyncOperation> deadLetters,
    required List<SyncFailure> failures,
    Future<void> Function(Duration duration)? delay,
    Duration baseBackoff = const Duration(seconds: 2),
    Duration maxBackoff = const Duration(seconds: 60),
    int maxAttempts = 8,
  })  : _database = database,
        _pending = pending,
        _deadLetters = deadLetters,
        _failures = failures,
        _delay = delay ?? Future<void>.delayed,
        _baseBackoff = baseBackoff,
        _maxBackoff = maxBackoff,
        _maxAttempts = maxAttempts;

  final SyncDriftDatabase _database;
  final List<_StoredOutboxOperation> _pending;
  final List<SyncOperation> _deadLetters;
  final List<SyncFailure> _failures;
  final Future<void> Function(Duration duration) _delay;
  final Duration _baseBackoff;
  final Duration _maxBackoff;
  final int _maxAttempts;
  final _pendingController = StreamController<SyncOperation>.broadcast();
  final _deadLetterController = StreamController<SyncOperation>.broadcast();
  final _errorController = StreamController<SyncFailure>.broadcast();

  static Future<DriftSyncOutbox> open(
    SyncDriftDatabase database, {
    required Map<Type, SyncAdapter<dynamic>> adapters,
    Future<void> Function(Duration duration)? delay,
    Duration baseBackoff = const Duration(seconds: 2),
    Duration maxBackoff = const Duration(seconds: 60),
    int maxAttempts = 8,
  }) async {
    final rows = await database
        .customSelect(
          'SELECT * FROM sync_outbox_operations ORDER BY id ASC',
        )
        .get();
    final pending = <_StoredOutboxOperation>[];
    final deadLetters = <SyncOperation>[];
    final failures = <SyncFailure>[];
    for (final row in rows) {
      final stored = _StoredOutboxOperation.fromRow(row, adapters);
      if (stored.deadLetter) {
        deadLetters.add(stored.operation);
        continue;
      }
      pending.add(stored);
      if (stored.lastError != null && stored.attempts > 0) {
        failures.add(
          SyncFailure(
            operation: stored.operation,
            kind: SyncFailureKind.rejected,
            reason: stored.lastError!,
            attempts: stored.attempts,
          ),
        );
      }
    }
    return DriftSyncOutbox._(
      database: database,
      pending: pending,
      deadLetters: deadLetters,
      failures: failures,
      delay: delay,
      baseBackoff: baseBackoff,
      maxBackoff: maxBackoff,
      maxAttempts: maxAttempts,
    );
  }

  @override
  Stream<SyncOperation> get pending => _pendingController.stream;

  @override
  Stream<SyncOperation> get deadLetter => _deadLetterController.stream;

  @override
  Stream<SyncFailure> get errors => _errorController.stream;

  @override
  List<SyncOperation> get pendingOperations =>
      List.unmodifiable(_pending.map((entry) => entry.operation));

  @override
  List<SyncOperation> get deadLetters => List.unmodifiable(_deadLetters);

  @override
  List<SyncFailure> get failures => List.unmodifiable(_failures);

  @override
  Future<void> queue(SyncOperation operation) async {
    if (operation is! DeleteOperation && operation.serializedEntity == null) {
      throw StateError(
        'Durable outbox requires serializedEntity for insert and update operations.',
      );
    }
    final stored = _StoredOutboxOperation.fromOperation(operation);
    await _database.customStatement(
      '''
INSERT INTO sync_outbox_operations (
  operation_kind,
  entity_type,
  entity_id,
  vector_clock,
  node_id,
  field_metadata,
  serialized_entity,
  attempts,
  next_attempt_at,
  last_error,
  dead_letter,
  created_at,
  updated_at
) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
''',
      [
        stored.operationKind,
        stored.entityType,
        stored.entityId,
        jsonEncode(stored.vectorClock.toJson()),
        stored.nodeId,
        stored.encodeFieldMetadata(),
        stored.encodeSerializedEntity(),
        stored.attempts,
        stored.nextAttemptAt,
        stored.lastError,
        stored.deadLetter ? 1 : 0,
        stored.createdAt,
        stored.updatedAt,
      ],
    );
    final row = await _database
        .customSelect('SELECT last_insert_rowid() AS id')
        .getSingle();
    _pending.add(stored.copyWith(id: row.read<int>('id')));
    _pendingController.add(operation);
  }

  @override
  Future<void> flush(SyncTransport transport) async {
    while (_pending.isNotEmpty) {
      final entry = _pending.first;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (entry.nextAttemptAt > now) {
        await _delay(Duration(milliseconds: entry.nextAttemptAt - now));
        continue;
      }
      try {
        final result = await transport.push([entry.operation]);
        if (result.results.length != 1) {
          throw StateError(
            'Transport returned ${result.results.length} results for a single operation.',
          );
        }
        final operationResult = result.results.single;
        if (operationResult.operation.entityType !=
                entry.operation.entityType ||
            operationResult.operation.entityId != entry.operation.entityId ||
            operationResult.operation.vectorClock !=
                entry.operation.vectorClock) {
          throw StateError(
            'Transport returned a result for a different operation.',
          );
        }
        switch (operationResult.disposition) {
          case SyncDisposition.accepted:
            await _deleteStored(entry);
            _pending.removeAt(0);
            break;
          case SyncDisposition.conflict:
            final clock = operationResult.updatedVectorClock ??
                entry.operation.vectorClock;
            final updated = entry.operation.withVectorClock(clock);
            final stored = entry.copyWith(
              operation: updated,
              vectorClock: clock,
              attempts: 0,
              nextAttemptAt: now,
              lastError: null,
            );
            await _replaceStored(entry.id, stored);
            _pending[0] = stored;
            break;
          case SyncDisposition.rejected:
            await _deleteStored(entry);
            _pending.removeAt(0);
            _recordFailure(
              entry.operation,
              SyncFailureKind.rejected,
              operationResult.reason ?? 'Server rejected operation',
              1,
            );
            break;
        }
      } catch (error) {
        final attempts = entry.attempts + 1;
        final failureReason = error.toString();
        if (attempts >= _maxAttempts) {
          final deadLetter = entry.copyWith(
            attempts: attempts,
            deadLetter: true,
            lastError: failureReason,
            updatedAt: now,
          );
          await _replaceStored(entry.id, deadLetter);
          _pending.removeAt(0);
          _deadLetters.add(deadLetter.operation);
          _deadLetterController.add(deadLetter.operation);
          _recordFailure(
            deadLetter.operation,
            SyncFailureKind.deadLetter,
            failureReason,
            attempts,
          );
          continue;
        }
        final delay = _baseBackoff * (1 << (attempts - 1)) > _maxBackoff
            ? _maxBackoff
            : _baseBackoff * (1 << (attempts - 1));
        final retry = entry.copyWith(
          attempts: attempts,
          nextAttemptAt: now + delay.inMilliseconds,
          lastError: failureReason,
          updatedAt: now,
        );
        await _replaceStored(entry.id, retry);
        _pending[0] = retry;
        await _delay(delay);
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _pendingController.close();
    await _deadLetterController.close();
    await _errorController.close();
  }

  Future<void> _deleteStored(_StoredOutboxOperation entry) =>
      _database.customStatement(
        'DELETE FROM sync_outbox_operations WHERE id=?',
        [entry.id],
      );

  Future<void> _replaceStored(int id, _StoredOutboxOperation stored) async {
    await _database.customStatement(
      '''
UPDATE sync_outbox_operations
SET
  operation_kind=?,
  entity_type=?,
  entity_id=?,
  vector_clock=?,
  node_id=?,
  field_metadata=?,
  serialized_entity=?,
  attempts=?,
  next_attempt_at=?,
  last_error=?,
  dead_letter=?,
  updated_at=?
WHERE id=?
''',
      [
        stored.operationKind,
        stored.entityType,
        stored.entityId,
        jsonEncode(stored.vectorClock.toJson()),
        stored.nodeId,
        stored.encodeFieldMetadata(),
        stored.encodeSerializedEntity(),
        stored.attempts,
        stored.nextAttemptAt,
        stored.lastError,
        stored.deadLetter ? 1 : 0,
        stored.updatedAt,
        id,
      ],
    );
  }

  void _recordFailure(
    SyncOperation operation,
    SyncFailureKind kind,
    String reason,
    int attempts,
  ) {
    final failure = SyncFailure(
      operation: operation,
      kind: kind,
      reason: reason,
      attempts: attempts,
    );
    _failures.add(failure);
    _errorController.add(failure);
  }
}

class _StoredOutboxOperation {
  _StoredOutboxOperation({
    required int? id,
    required this.operationKind,
    required this.entityType,
    required this.entityId,
    required this.vectorClock,
    required this.nodeId,
    required this.fieldMetadata,
    required this.serializedEntity,
    required this.attempts,
    required this.nextAttemptAt,
    required this.lastError,
    required this.deadLetter,
    required this.createdAt,
    required this.updatedAt,
    required this.operation,
  }) : id = id ?? -1;

  final int id;
  final String operationKind;
  final String entityType;
  final String entityId;
  final VectorClock vectorClock;
  final String nodeId;
  final Map<String, FieldLwwMetadata> fieldMetadata;
  final Map<String, dynamic>? serializedEntity;
  final int attempts;
  final int nextAttemptAt;
  final String? lastError;
  final bool deadLetter;
  final int createdAt;
  final int updatedAt;
  final SyncOperation operation;

  factory _StoredOutboxOperation.fromOperation(SyncOperation operation) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _StoredOutboxOperation(
      id: 0,
      operationKind: switch (operation) {
        InsertOperation() => 'insert',
        UpdateOperation() => 'update',
        DeleteOperation() => 'delete',
      },
      entityType: operation.entityType,
      entityId: operation.entityId,
      vectorClock: operation.vectorClock,
      nodeId: operation.nodeId,
      fieldMetadata: operation.fieldMetadata,
      serializedEntity: operation.serializedEntity,
      attempts: 0,
      nextAttemptAt: now,
      lastError: null,
      deadLetter: false,
      createdAt: now,
      updatedAt: now,
      operation: operation,
    );
  }

  factory _StoredOutboxOperation.fromRow(
    QueryRow row,
    Map<Type, SyncAdapter<dynamic>> adapters,
  ) {
    final id = row.read<int>('id');
    final operationKind = row.read<String>('operation_kind');
    final entityType = row.read<String>('entity_type');
    final adapter = adapters.values.firstWhere(
      (candidate) => candidate.entityType == entityType,
      orElse: () => throw UnregisteredSyncTypeError(entityType),
    );
    final vectorClock = VectorClock.fromJson(
      jsonDecode(row.read<String>('vector_clock')) as Map<String, dynamic>,
    );
    final fieldMetadata = ((jsonDecode(row.read<String>('field_metadata'))
                as Map<String, dynamic>?) ??
            const {})
        .map((key, value) => MapEntry(
              key,
              FieldLwwMetadata.fromJson(value as Map<String, dynamic>),
            ));
    final serializedEntity = row.readNullable<String>('serialized_entity');
    final decodedEntity = serializedEntity == null
        ? null
        : jsonDecode(serializedEntity) as Map<String, dynamic>;
    final operation = switch (operationKind) {
      'insert' => InsertOperation(
          entityType: entityType,
          entityId: row.read<String>('entity_id'),
          vectorClock: vectorClock,
          nodeId: row.read<String>('node_id'),
          fieldMetadata: fieldMetadata,
          serializedEntity: decodedEntity,
          entity: adapter.fromJson(decodedEntity!),
        ),
      'update' => UpdateOperation(
          entityType: entityType,
          entityId: row.read<String>('entity_id'),
          vectorClock: vectorClock,
          nodeId: row.read<String>('node_id'),
          fieldMetadata: fieldMetadata,
          serializedEntity: decodedEntity,
          entity: adapter.fromJson(decodedEntity!),
        ),
      'delete' => DeleteOperation(
          entityType: entityType,
          entityId: row.read<String>('entity_id'),
          vectorClock: vectorClock,
          nodeId: row.read<String>('node_id'),
          fieldMetadata: fieldMetadata,
          serializedEntity: null,
        ),
      _ => throw StateError('Unknown outbox operation kind: $operationKind'),
    };
    return _StoredOutboxOperation(
      id: id,
      operationKind: operationKind,
      entityType: entityType,
      entityId: row.read<String>('entity_id'),
      vectorClock: vectorClock,
      nodeId: row.read<String>('node_id'),
      fieldMetadata: fieldMetadata,
      serializedEntity: decodedEntity,
      attempts: row.read<int>('attempts'),
      nextAttemptAt: row.read<int>('next_attempt_at'),
      lastError: row.readNullable<String>('last_error'),
      deadLetter: row.read<int>('dead_letter') == 1,
      createdAt: row.read<int>('created_at'),
      updatedAt: row.read<int>('updated_at'),
      operation: operation,
    );
  }

  _StoredOutboxOperation copyWith({
    int? id,
    SyncOperation? operation,
    VectorClock? vectorClock,
    int? attempts,
    int? nextAttemptAt,
    String? lastError,
    bool? deadLetter,
    int? updatedAt,
  }) {
    return _StoredOutboxOperation(
      id: id ?? this.id,
      operationKind: operationKind,
      entityType: entityType,
      entityId: entityId,
      vectorClock: vectorClock ?? this.vectorClock,
      nodeId: nodeId,
      fieldMetadata: fieldMetadata,
      serializedEntity: serializedEntity,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError,
      deadLetter: deadLetter ?? this.deadLetter,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      operation: operation ?? this.operation,
    );
  }

  String encodeFieldMetadata() => jsonEncode(
      fieldMetadata.map((key, value) => MapEntry(key, value.toJson())));

  String? encodeSerializedEntity() =>
      serializedEntity == null ? null : jsonEncode(serializedEntity);
}
