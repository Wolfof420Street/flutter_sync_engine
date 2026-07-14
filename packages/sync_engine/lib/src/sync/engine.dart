import 'dart:async';

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

/// Coordinates optimistic local changes with a pluggable transport and storage.
class SyncEngine {
  SyncEngine({
    required SyncStorage storage,
    required SyncTransport transport,
    SyncOutbox? outbox,
    this.nodeId = 'local',
    Map<Type, SyncAdapter<dynamic>> adapters = const {},
  })  : _storage = storage,
        _transport = transport,
        _outbox = outbox ?? SyncOutbox(),
        _adapters = Map<Type, SyncAdapter<dynamic>>.from(adapters) {
    _notificationSubscription = _transport.notifications.listen((_) {
      unawaited(sync());
    });
  }

  final SyncStorage _storage;
  final SyncTransport _transport;
  final SyncOutbox _outbox;
  final String nodeId;
  final Map<Type, SyncAdapter<dynamic>> _adapters;
  final Map<SyncOperation, _Rollback> _rollbacks = {};
  final _conflictController = StreamController<ConflictResolution>.broadcast();
  late final StreamSubscription<SyncNotification> _notificationSubscription;
  String _lastSyncToken = '';
  int _handledFailures = 0;

  Stream<ConflictResolution> get conflicts => _conflictController.stream;
  SyncOutbox get outbox => _outbox;

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
    final previous = await _storage.load<T>(id);
    final operation = InsertOperation(
      entityType: adapter.entityType,
      entityId: id,
      vectorClock: VectorClock().increment(nodeId),
      entity: entity,
    );
    await _storage.save(id, entity, operation.vectorClock);
    _rollbacks[operation] = _Rollback<T>(previous, operation.vectorClock);
    _outbox.queue(operation);
  }

  /// Saves [entity] locally, then queues an update for a later sync.
  Future<void> update<T>(T entity) async {
    final adapter = _adapterFor<T>();
    final id = adapter.idOf(entity);
    final previous = await _storage.load<T>(id);
    final operation = UpdateOperation(
      entityType: adapter.entityType,
      entityId: id,
      vectorClock: VectorClock().increment(nodeId),
      entity: entity,
    );
    await _storage.save(id, entity, operation.vectorClock);
    _rollbacks[operation] = _Rollback<T>(previous, operation.vectorClock);
    _outbox.queue(operation);
  }

  /// Writes a local tombstone and queues a delete operation.
  Future<void> delete<T>(String id) async {
    final adapter = _adapterFor<T>();
    final previous = await _storage.load<T>(id);
    final operation = DeleteOperation(
      entityType: adapter.entityType,
      entityId: id,
      vectorClock: VectorClock().increment(nodeId),
    );
    await _storage.delete<T>(id);
    _rollbacks[operation] = _Rollback<T>(previous, operation.vectorClock);
    _outbox.queue(operation);
  }

  /// Performs one pull/push cycle and handles permanent optimistic failures.
  Future<void> sync() async {
    final batch = await _transport.pull(lastSyncToken: _lastSyncToken);
    _lastSyncToken = batch.nextSyncToken;
    await _outbox.flush(_transport);
    await _processFailures();
    await _pruneAcknowledgedFrontiers();
  }

  SyncAdapter<T> _adapterFor<T>() {
    final adapter = _adapters[T];
    if (adapter == null) throw UnregisteredSyncTypeError(T);
    return adapter as SyncAdapter<T>;
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

  /// Reserved for Phase 4's persisted, per-replica acknowledgement frontier.
  Future<void> _pruneAcknowledgedFrontiers() async {
    // TODO(sync-engine#phase4): prune only after every known replica has
    // acknowledged a vector clock that succeeds the frontier entry.
  }

  Future<void> dispose() async {
    await _notificationSubscription.cancel();
    await _conflictController.close();
    await _outbox.dispose();
  }
}

class _Rollback<T> {
  const _Rollback(this.previous, this.clock);

  final T? previous;
  final VectorClock clock;

  Future<void> restore(SyncStorage storage, String id) async {
    if (previous == null) {
      await storage.delete<T>(id);
    } else {
      await storage.save<T>(id, previous as T, clock);
    }
  }
}
