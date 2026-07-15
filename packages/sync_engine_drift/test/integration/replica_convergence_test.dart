// This test uses an in-process relay because the example app's
// RUN_HTTP_INTEGRATION suite already verifies the Shelf/HTTP wire contract.
// Its distinct responsibility is CRDT convergence through real SyncEngine and
// DriftSyncStorage instances without introducing HTTP timing into the result.

import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:sync_engine_drift/sync_engine_drift.dart';
import 'package:task_manager/task.dart';
import 'package:test/test.dart';

import '../support/sqlite3_test_loader.dart';

class _RelayEntry {
  const _RelayEntry(this.operation);

  final SyncOperation operation;
}

/// A shared relay with per-client cursors and acknowledgement clocks.
class _OperationRelay {
  final List<_RelayEntry> _entries = [];
  final Map<String, Map<String, VectorClock>> _seenByReplica = {};

  SyncTransport transportFor(String replicaId) =>
      _RelayTransport(this, replicaId);

  Future<SyncBatch> pull(String replicaId, String token) async {
    final index = int.tryParse(token) ?? 0;
    final unseen = _entries.skip(index).toList();
    for (final entry in unseen) {
      _recordSeen(replicaId, entry.operation);
    }
    return SyncBatch(
      operations: [for (final entry in unseen) entry.operation],
      nextSyncToken: _entries.length.toString(),
      acknowledgements: [
        for (final replica in _seenByReplica.entries)
          for (final state in replica.value.entries)
            ReplicaAcknowledgement(
              entityType: _typeOf(state.key),
              entityId: _idOf(state.key),
              nodeId: replica.key,
              acknowledgedClock: state.value,
            ),
      ],
    );
  }

  Future<SyncResult> push(
      String replicaId, List<SyncOperation> operations) async {
    for (final operation in operations) {
      _entries.add(_RelayEntry(operation));
      // Sending a write means this replica has observed its own clock.
      _recordSeen(replicaId, operation);
    }
    return SyncResult.accepted(operations);
  }

  void _recordSeen(String replicaId, SyncOperation operation) {
    final states = _seenByReplica.putIfAbsent(replicaId, () => {});
    final key = '${operation.entityType}\u0000${operation.entityId}';
    states[key] = (states[key] ?? VectorClock()).merge(operation.vectorClock);
  }

  String _typeOf(String key) => key.split('\u0000').first;
  String _idOf(String key) => key.split('\u0000').last;
}

class _RelayTransport implements SyncTransport {
  _RelayTransport(this._relay, this._replicaId);

  final _OperationRelay _relay;
  final String _replicaId;

  @override
  Stream<SyncNotification> get notifications => const Stream.empty();

  @override
  Future<SyncBatch> pull({required String lastSyncToken}) =>
      _relay.pull(_replicaId, lastSyncToken);

  @override
  Future<SyncResult> push(List<SyncOperation> operations) =>
      _relay.push(_replicaId, operations);
}

class _Replica {
  _Replica(this.nodeId, this.database, this.storage, this.engine);

  final String nodeId;
  final SyncDriftDatabase database;
  final DriftSyncStorage storage;
  final SyncEngine engine;

  Future<void> dispose() async {
    await engine.dispose();
    await database.close();
  }
}

Future<_Replica> _replica(String nodeId, _OperationRelay relay) async {
  final database = SyncDriftDatabase(NativeDatabase.memory());
  final adapter = const TaskSyncAdapter();
  final storage = DriftSyncStorage(
    database,
    adapters: {Task: adapter},
    knownReplicas: const {'a', 'b'},
  );
  final engine = SyncEngine(
    storage: storage,
    transport: relay.transportFor(nodeId),
    nodeId: nodeId,
    adapters: {Task: adapter},
  );
  return _Replica(nodeId, database, storage, engine);
}

Future<void> _seed(_Replica a, _Replica b, Task baseline) async {
  await a.engine.insert(baseline);
  await a.engine.sync();
  await b.engine.sync();
}

Future<void> _converge(_Replica a, _Replica b) async {
  // Sync pulls before it pushes. Two rounds ensure each replica pulls the
  // other offline operation after both have published it.
  await a.engine.sync();
  await b.engine.sync();
  await a.engine.sync();
  await b.engine.sync();
}

void main() {
  setUpAll(() {
    configureSqliteForTests();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test('concurrent different-field updates converge regardless of sync order',
      () async {
    for (final aFirst in [true, false]) {
      final relay = _OperationRelay();
      final a = await _replica('a', relay);
      final b = await _replica('b', relay);
      addTearDown(() async {
        await a.dispose();
        await b.dispose();
      });

      const baseline = Task(id: 'task-1', title: 'baseline', completed: false);
      await _seed(a, b, baseline);
      await a.engine.update(baseline.copyWith(title: 'from a'));
      await b.engine.update(baseline.copyWith(completed: true));
      if (aFirst) {
        await _converge(a, b);
      } else {
        await _converge(b, a);
      }

      final aState = await a.storage.loadStored(Task, baseline.id);
      final bState = await b.storage.loadStored(Task, baseline.id);
      final aTask = aState!.value! as Task;
      final bTask = bState!.value! as Task;
      expect(aTask.id, baseline.id);
      expect(aTask.title, 'from a');
      expect(aTask.completed, isTrue);
      expect(bTask.id, aTask.id);
      expect(bTask.title, aTask.title);
      expect(bTask.completed, aTask.completed);
      expect(bState.clock, aState.clock);
    }
  });

  test(
      'concurrent same-field updates choose the shared LWW winner and emit a conflict',
      () async {
    final relay = _OperationRelay();
    final a = await _replica('a', relay);
    final b = await _replica('b', relay);
    addTearDown(() async {
      await a.dispose();
      await b.dispose();
    });
    const baseline = Task(id: 'task-2', title: 'baseline', completed: false);
    await _seed(a, b, baseline);
    await a.engine.update(baseline.copyWith(title: 'from a'));
    await b.engine.update(baseline.copyWith(title: 'from b'));
    final conflicts = <ConflictResolution>[];
    final subscription = a.engine.conflicts.listen(conflicts.add);
    addTearDown(subscription.cancel);

    await _converge(a, b);

    final winner = LWWRegister.winningNodeId('a', 'b');
    final expectedTitle = winner == 'a' ? 'from a' : 'from b';
    final aTask = (await a.storage.load<Task>(baseline.id))!;
    final bTask = (await b.storage.load<Task>(baseline.id))!;
    expect(aTask.title, expectedTitle);
    expect(bTask.id, baseline.id);
    expect(bTask.title, expectedTitle);
    expect(bTask.completed, isFalse);
    expect(conflicts, isNotEmpty);
  });

  test('concurrent update versus delete converges to a tombstone', () async {
    final relay = _OperationRelay();
    final a = await _replica('a', relay);
    final b = await _replica('b', relay);
    addTearDown(() async {
      await a.dispose();
      await b.dispose();
    });
    const baseline = Task(id: 'task-3', title: 'baseline', completed: false);
    await _seed(a, b, baseline);
    await a.engine.update(baseline.copyWith(title: 'updated by a'));
    await b.engine.delete<Task>(baseline.id);
    await _converge(a, b);

    // SyncEngine deliberately chooses delete-wins for concurrent operations.
    expect(await a.storage.load<Task>(baseline.id), isNull);
    expect(await b.storage.load<Task>(baseline.id), isNull);
    expect((await a.storage.loadStored(Task, baseline.id))!.deleted, isTrue);
    expect((await b.storage.loadStored(Task, baseline.id))!.deleted, isTrue);
  });
}
