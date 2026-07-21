import 'dart:async';

import '../crdt/lww_register.dart';
import '../vector_clock.dart';
import 'adapter.dart';
import 'interfaces.dart';
import 'operation.dart';
import 'outbox.dart';

/// Describes a server failure and any compensating local write it caused.
class ConflictResolution {
  const ConflictResolution({
    required this.operation,
    required this.reason,
    required this.rolledBack,
  });

  final SyncOperation operation;
  final String reason;
  final bool rolledBack;
}

/// Synchronizes annotated models with a remote backend.
///
/// Supports optimistic local writes, CRDT conflict resolution, offline queues,
/// retries, and compensating rollbacks. Persistence and networking are supplied
/// through [SyncStorage] and [SyncTransport].
class SyncEngine {
  SyncEngine({
    required SyncStorage storage,
    required SyncTransport transport,
    SyncOperationQueue? outbox,
    this.nodeId = 'local',
    Map<Type, SyncAdapter<dynamic>> adapters = const {},
  })  : _storage = storage,
        _transport = transport,
        _outbox = outbox ?? SyncOutbox(),
        _adapters = Map<Type, SyncAdapter<dynamic>>.from(adapters) {
    _notificationSubscription = _transport.notifications.listen((_) {
      unawaited(sync().catchError((Object _) {}));
    });
  }

  final SyncStorage _storage;
  final SyncTransport _transport;
  final SyncOperationQueue _outbox;
  final String nodeId;
  final Map<Type, SyncAdapter<dynamic>> _adapters;
  final Map<SyncOperation, _Rollback> _rollbacks = {};
  final _conflictController = StreamController<ConflictResolution>.broadcast();
  late final StreamSubscription<SyncNotification> _notificationSubscription;
  Future<void>? _syncFuture;
  String _lastSyncToken = '';
  int _handledFailures = 0;

  /// Emits outbound rejections and concurrent inbound merge resolutions.
  Stream<ConflictResolution> get conflicts => _conflictController.stream;
  SyncOperationQueue get outbox => _outbox;

  /// Registers an adapter until Phase 3 generator output supplies the registry.
  void register<T>(SyncAdapter<T> adapter) {
    _adapters[T] = adapter;
  }

  /// Watches all locally stored entities of type [T].
  Stream<List<T>> watch<T>() {
    _adapterFor<T>();
    return _storage.watch<T>();
  }

  /// Saves [entity] locally, then queues an insert for a later sync.
  Future<void> insert<T>(T entity) async {
    final adapter = _adapterFor<T>();
    final id = adapter.idOf(entity);
    final previousState = await _storage.loadStored(adapter.modelType, id);
    final clock = (previousState?.clock ?? VectorClock()).increment(nodeId);
    final operation = InsertOperation(
      entityType: adapter.entityType,
      entityId: id,
      vectorClock: clock,
      nodeId: nodeId,
      fieldMetadata: adapter.fieldMetadataForWrite(
          entity,
          previousState?.value as T?,
          previousState?.fieldMetadata ?? const {},
          clock,
          nodeId),
      serializedEntity: adapter.toJson(entity),
      entity: entity,
    );
    await _storage.saveStored(adapter.modelType, id, entity as Object,
        operation.vectorClock, nodeId, operation.fieldMetadata);
    _rollbacks[operation] = _Rollback(
        previousState, adapter.modelType, operation.vectorClock, nodeId);
    await _outbox.queue(operation);
  }

  /// Saves [entity] locally, then queues an update for a later sync.
  Future<void> update<T>(T entity) async {
    final adapter = _adapterFor<T>();
    final id = adapter.idOf(entity);
    final previousState = await _storage.loadStored(adapter.modelType, id);
    final clock = (previousState?.clock ?? VectorClock()).increment(nodeId);
    final operation = UpdateOperation(
      entityType: adapter.entityType,
      entityId: id,
      vectorClock: clock,
      nodeId: nodeId,
      fieldMetadata: adapter.fieldMetadataForWrite(
          entity,
          previousState?.value as T?,
          previousState?.fieldMetadata ?? const {},
          clock,
          nodeId),
      serializedEntity: adapter.toJson(entity),
      entity: entity,
    );
    await _storage.saveStored(adapter.modelType, id, entity as Object,
        operation.vectorClock, nodeId, operation.fieldMetadata);
    _rollbacks[operation] = _Rollback(
        previousState, adapter.modelType, operation.vectorClock, nodeId);
    await _outbox.queue(operation);
  }

  /// Writes a local tombstone and queues a delete operation.
  Future<void> delete<T>(String id) async {
    final adapter = _adapterFor<T>();
    final previousState = await _storage.loadStored(adapter.modelType, id);
    final clock = (previousState?.clock ?? VectorClock()).increment(nodeId);
    final operation = DeleteOperation(
      entityType: adapter.entityType,
      entityId: id,
      vectorClock: clock,
      nodeId: nodeId,
    );
    await _storage.deleteStored(
        adapter.modelType, id, operation.vectorClock, nodeId);
    _rollbacks[operation] = _Rollback(
        previousState, adapter.modelType, operation.vectorClock, nodeId);
    await _outbox.queue(operation);
  }

  /// Performs one pull/push cycle and handles permanent optimistic failures.
  Future<void> sync() async {
    final running = _syncFuture;
    if (running != null) {
      await running;
      return;
    }

    final future = _runSync();
    _syncFuture = future;
    try {
      await future;
    } finally {
      if (identical(_syncFuture, future)) {
        _syncFuture = null;
      }
    }
  }

  Future<void> _runSync() async {
    final initialFailureCount = _outbox.failures.length;
    final batch = await _transport.pull(lastSyncToken: _lastSyncToken);
    for (final operation in batch.operations) {
      await _applyIncoming(operation);
    }
    await _outbox.flush(_transport);
    await _processFailures();
    if (_storage case final SyncAcknowledgementStorage acknowledgementStorage) {
      await acknowledgementStorage
          .recordAcknowledgements(batch.acknowledgements);
      await acknowledgementStorage.pruneAcknowledgedFrontiers();
    }
    if (_outbox.failures.length == initialFailureCount) {
      _lastSyncToken = batch.nextSyncToken;
    }
  }

  SyncAdapter<T> _adapterFor<T>() {
    final adapter = _adapters[T];
    if (adapter == null) throw UnregisteredSyncTypeError(T);
    return adapter as SyncAdapter<T>;
  }

  Future<void> _applyIncoming(SyncOperation incoming) async {
    final adapter = _adapters.values.cast<SyncAdapter<dynamic>?>().firstWhere(
        (candidate) => candidate?.entityType == incoming.entityType,
        orElse: () => null);
    if (adapter == null) throw UnregisteredSyncTypeError(incoming.entityType);
    final current =
        await _storage.loadStored(adapter.modelType, incoming.entityId);
    final incomingIsDelete = incoming is DeleteOperation;
    if (current == null) {
      if (incomingIsDelete) {
        await _storage.deleteStored(adapter.modelType, incoming.entityId,
            incoming.vectorClock, incoming.nodeId, incoming.fieldMetadata);
      } else {
        await _storage.saveStored(
            adapter.modelType,
            incoming.entityId,
            incoming.entity as Object,
            incoming.vectorClock,
            incoming.nodeId,
            incoming.fieldMetadata);
      }
      return;
    }
    final incomingAfter = incoming.vectorClock.happenedAfter(current.clock);
    final currentAfter = current.clock.happenedAfter(incoming.vectorClock);
    final concurrent = incoming.vectorClock.isConcurrent(current.clock);
    if (incomingIsDelete) {
      if (!currentAfter) {
        final clock = concurrent
            ? current.clock.merge(incoming.vectorClock)
            : incoming.vectorClock;
        await _storage.deleteStored(adapter.modelType, incoming.entityId, clock,
            incoming.nodeId, incoming.fieldMetadata);
      }
      return;
    }
    if (current.deleted) {
      // Delete wins concurrent updates; a causally later update may resurrect.
      if (incomingAfter) {
        await _storage.saveStored(
            adapter.modelType,
            incoming.entityId,
            incoming.entity as Object,
            incoming.vectorClock,
            incoming.nodeId,
            incoming.fieldMetadata);
      }
      return;
    }
    if (incomingAfter) {
      await _storage.saveStored(
          adapter.modelType,
          incoming.entityId,
          incoming.entity as Object,
          incoming.vectorClock,
          incoming.nodeId,
          incoming.fieldMetadata);
      return;
    }
    if (currentAfter) return;
    if (concurrent) {
      final merged = adapter.merge(
          current.value,
          incoming.entity,
          current.clock,
          incoming.vectorClock,
          current.nodeId,
          incoming.nodeId,
          current.fieldMetadata,
          incoming.fieldMetadata);
      _conflictController.add(ConflictResolution(
        operation: incoming,
        reason:
            'Concurrent inbound merge for ${incoming.entityType}/${incoming.entityId}; '
            'field-local conflict strategy selected the persisted winner.',
        rolledBack: false,
      ));
      await _storage.saveStored(
          adapter.modelType,
          incoming.entityId,
          merged.value,
          current.clock.merge(incoming.vectorClock),
          LWWRegister.winningNodeId(current.nodeId, incoming.nodeId),
          merged.fieldMetadata);
    }
  }

  Future<void> _processFailures() async {
    final failures = _outbox.failures;
    while (_handledFailures < failures.length) {
      final failure = failures[_handledFailures++];
      final rollback = _rollbacks.remove(failure.operation);
      if (rollback == null) {
        _conflictController.add(ConflictResolution(
            operation: failure.operation,
            reason: failure.reason,
            rolledBack: false));
        continue;
      }
      await rollback.restore(_storage, failure.operation.entityId);
      _conflictController.add(ConflictResolution(
          operation: failure.operation,
          reason: failure.reason,
          rolledBack: true));
    }
  }

  Future<void> dispose() async {
    await _notificationSubscription.cancel();
    await _conflictController.close();
    await _outbox.dispose();
  }
}

class _Rollback {
  const _Rollback(this.previous, this.modelType, this.failedClock, this.nodeId);

  final SyncStoredEntity<Object?>? previous;
  final Type modelType;
  final VectorClock failedClock;
  final String nodeId;

  Future<void> restore(SyncStorage storage, String id) async {
    final state = previous;
    if (state == null) {
      await storage.deleteStored(modelType, id, failedClock, nodeId);
    } else if (state.deleted) {
      await storage.deleteStored(
          modelType, id, state.clock, state.nodeId, state.fieldMetadata);
    } else {
      await storage.saveStored(modelType, id, state.value!, state.clock,
          state.nodeId, state.fieldMetadata);
    }
  }
}
