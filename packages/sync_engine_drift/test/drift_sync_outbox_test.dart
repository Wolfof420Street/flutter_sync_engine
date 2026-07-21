import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:sync_engine_drift/sync_engine_drift.dart';
import 'package:test/test.dart';

import 'support/sqlite3_test_loader.dart';

import 'package:task_manager/task.dart';

void main() {
  setUpAll(configureSqliteForTests);

  test('restores pending operations across restart and flushes them', () async {
    final database = SyncDriftDatabase(NativeDatabase.memory());
    final adapters = {Task: const TaskSyncAdapter()};
    final outbox = await DriftSyncOutbox.open(database, adapters: adapters);
    final operation = InsertOperation(
      entityType: 'task',
      entityId: 'one',
      vectorClock: VectorClock({'a': 1}),
      nodeId: 'a',
      serializedEntity: const TaskSerializer().toJson(
        const Task(id: 'one', title: 'first'),
      ),
      entity: const Task(id: 'one', title: 'first'),
    );

    await outbox.queue(operation);
    expect(outbox.pendingOperations, [operation]);

    await outbox.dispose();
    final reopened = await DriftSyncOutbox.open(database, adapters: adapters);
    expect(reopened.pendingOperations, [operation]);

    await reopened.flush(FakeSyncTransport());

    expect(reopened.pendingOperations, isEmpty);
    final remaining = await database
        .customSelect(
          'SELECT count(*) AS count FROM sync_outbox_operations',
        )
        .getSingle();
    expect(remaining.read<int>('count'), 0);
    await reopened.dispose();
    await database.close();
  });

  test('persists retry metadata while waiting for the next attempt', () async {
    final database = SyncDriftDatabase(NativeDatabase.memory());
    final adapters = {Task: const TaskSyncAdapter()};
    final delayDurations = <Duration>[];
    final delayGate = Completer<void>();
    final delayStarted = Completer<void>();
    final outbox = await DriftSyncOutbox.open(
      database,
      adapters: adapters,
      baseBackoff: const Duration(milliseconds: 10),
      maxBackoff: const Duration(milliseconds: 10),
      maxAttempts: 3,
      delay: (duration) async {
        delayDurations.add(duration);
        if (!delayStarted.isCompleted) delayStarted.complete();
        await delayGate.future;
      },
    );
    final operation = UpdateOperation(
      entityType: 'task',
      entityId: 'one',
      vectorClock: VectorClock({'a': 1}),
      nodeId: 'a',
      serializedEntity: const TaskSerializer().toJson(
        const Task(id: 'one', title: 'retry'),
      ),
      entity: const Task(id: 'one', title: 'retry'),
    );
    final transport = FakeSyncTransport(responses: [
      Exception('offline'),
      SyncResult.accepted(const <SyncOperation>[]),
    ]);
    await outbox.queue(operation);

    final flush = outbox.flush(transport);
    await delayStarted.future;

    final row = await database.customSelect(
      'SELECT attempts, next_attempt_at, dead_letter FROM sync_outbox_operations WHERE entity_id=?',
      variables: [Variable<String>('one')],
    ).getSingle();
    expect(row.read<int>('attempts'), 1);
    expect(row.read<int>('dead_letter'), 0);
    expect(row.read<int>('next_attempt_at'), greaterThan(0));
    expect(delayDurations, [const Duration(milliseconds: 10)]);

    delayGate.complete();
    await flush;

    expect(outbox.pendingOperations, isEmpty);
    await outbox.dispose();
    await database.close();
  });

  test('persists dead letters after exhausting retry attempts', () async {
    final database = SyncDriftDatabase(NativeDatabase.memory());
    final adapters = {Task: const TaskSyncAdapter()};
    final outbox = await DriftSyncOutbox.open(
      database,
      adapters: adapters,
      baseBackoff: const Duration(milliseconds: 1),
      maxBackoff: const Duration(milliseconds: 1),
      maxAttempts: 2,
      delay: (_) async {},
    );
    final operation = DeleteOperation(
      entityType: 'task',
      entityId: 'one',
      vectorClock: VectorClock({'a': 1}),
      nodeId: 'a',
    );
    await outbox.queue(operation);

    await outbox.flush(
      FakeSyncTransport(
          responses: [Exception('offline'), Exception('offline')]),
    );

    final reopened = await DriftSyncOutbox.open(database, adapters: adapters);
    expect(reopened.pendingOperations, isEmpty);
    expect(reopened.deadLetters, isNotEmpty);
    expect(reopened.deadLetters.single.entityId, 'one');
    await reopened.dispose();
    await outbox.dispose();
    await database.close();
  });
}

class FakeSyncTransport implements SyncTransport {
  FakeSyncTransport({List<Object> responses = const []})
      : _responses = List<Object>.from(responses);

  final List<Object> _responses;

  @override
  Stream<SyncNotification> get notifications => const Stream.empty();

  @override
  Future<SyncBatch> pull({required String lastSyncToken}) async =>
      const SyncBatch();

  @override
  Future<SyncResult> push(List<SyncOperation> operations) async {
    final response = _responses.isEmpty
        ? SyncResult.accepted(operations)
        : _responses.removeAt(0);
    if (response is Exception) {
      throw response;
    }
    return response as SyncResult;
  }
}
