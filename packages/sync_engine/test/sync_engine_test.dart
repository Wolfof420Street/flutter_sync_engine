import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  SyncEngine engine(FakeSyncStorage storage, FakeSyncTransport transport) =>
      SyncEngine(
        storage: storage,
        transport: transport,
        adapters: {Task: TaskAdapter()},
      );

  test('insert, update, delete optimistically update local storage', () async {
    final storage = FakeSyncStorage();
    final syncEngine = engine(storage, FakeSyncTransport());
    await syncEngine.insert(const Task('one', 'first'));
    expect(await storage.load<Task>('one'), const Task('one', 'first'));
    await syncEngine.update(const Task('one', 'second'));
    expect(await storage.load<Task>('one'), const Task('one', 'second'));
    await syncEngine.delete<Task>('one');
    expect(await storage.load<Task>('one'), isNull);
  });

  test('watch is delegated to registered local storage', () async {
    final storage = FakeSyncStorage();
    final syncEngine = engine(storage, FakeSyncTransport());
    final values = <List<Task>>[];
    final subscription = syncEngine.watch<Task>().listen(values.add);

    await syncEngine.insert(const Task('one', 'first'));
    await Future<void>.delayed(Duration.zero);

    expect(values.last, [const Task('one', 'first')]);
    await subscription.cancel();
  });

  test('rejected optimistic insert is rolled back and emits a conflict',
      () async {
    final storage = FakeSyncStorage();
    final rejected = InsertOperation(
      entityType: 'task',
      entityId: 'one',
      vectorClock: VectorClock({'local': 1}),
      entity: const Task('one', 'first'),
    );
    final transport = FakeSyncTransport(responses: [
      SyncResult(results: [
        SyncOperationResult(
            operation: rejected,
            disposition: SyncDisposition.rejected,
            reason: 'policy denied'),
      ]),
    ]);
    final syncEngine = engine(storage, transport);
    final conflict = syncEngine.conflicts.first;
    await syncEngine.insert(const Task('one', 'first'));

    await syncEngine.sync();

    expect(await storage.load<Task>('one'), isNull);
    expect((await conflict).rolledBack, isTrue);
    expect(transport.pulls, 1);
  });

  test(
      'rejected optimistic update is rolled back to the prior value and emits a conflict',
      () async {
    final storage = FakeSyncStorage();
    final rejected = UpdateOperation(
      entityType: 'task',
      entityId: 'one',
      vectorClock: VectorClock({'local': 1}),
      entity: const Task('one', 'rejected update'),
    );
    final transport = FakeSyncTransport(responses: [
      const SyncResult(),
      SyncResult(results: [
        SyncOperationResult(
          operation: rejected,
          disposition: SyncDisposition.rejected,
          reason: 'policy denied update',
        ),
      ]),
    ]);
    final syncEngine = engine(storage, transport);
    final watched = <List<Task>>[];
    final watchSubscription = syncEngine.watch<Task>().listen(watched.add);
    final conflict = syncEngine.conflicts.first;

    await syncEngine.insert(const Task('one', 'original'));
    await syncEngine.update(const Task('one', 'rejected update'));
    await syncEngine.sync();
    await Future<void>.delayed(Duration.zero);

    expect(await storage.load<Task>('one'), const Task('one', 'original'));
    expect(watched.last, [const Task('one', 'original')]);
    expect((await conflict).reason, 'policy denied update');
    await watchSubscription.cancel();
  });

  test('throws a clear error for an unregistered type', () {
    final syncEngine =
        SyncEngine(storage: FakeSyncStorage(), transport: FakeSyncTransport());
    expect(() => syncEngine.watch<Task>(),
        throwsA(isA<UnregisteredSyncTypeError>()));
  });
}
