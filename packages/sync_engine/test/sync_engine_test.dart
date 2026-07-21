import 'dart:async';
import 'dart:collection';

import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  SyncEngine engine(
    FakeSyncStorage storage,
    FakeSyncTransport transport, {
    SyncOperationQueue? outbox,
  }) =>
      SyncEngine(
        storage: storage,
        transport: transport,
        outbox: outbox,
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
    final inserted = InsertOperation(
      entityType: 'task',
      entityId: 'one',
      vectorClock: VectorClock({'local': 1}),
      entity: const Task('one', 'original'),
    );
    final rejected = UpdateOperation(
      entityType: 'task',
      entityId: 'one',
      vectorClock: VectorClock({'local': 2}),
      entity: const Task('one', 'rejected update'),
    );
    final transport = FakeSyncTransport(responses: [
      SyncResult(results: [
        SyncOperationResult(
          operation: inserted,
          disposition: SyncDisposition.accepted,
        ),
      ]),
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

  test('serializes concurrent sync calls onto one transport pull', () async {
    final storage = FakeSyncStorage();
    final transport = _BlockingSyncTransport();
    final syncEngine = engine(storage, transport);

    final first = syncEngine.sync();
    await Future<void>.delayed(Duration.zero);
    final second = syncEngine.sync();
    await Future<void>.delayed(Duration.zero);

    expect(transport.pullCount, 1);
    transport.completePull();

    await Future.wait([first, second]);

    expect(transport.pullCount, 1);
  });

  test('retains the sync cursor when push fails after a successful pull',
      () async {
    final storage = FakeSyncStorage();
    final transport = _CursorTrackingTransport(
      batch: SyncBatch(
        operations: [
          UpdateOperation(
            entityType: 'task',
            entityId: 'remote',
            vectorClock: VectorClock({'remote': 1}),
            nodeId: 'remote',
            entity: const Task('remote', 'remote'),
          ),
        ],
        nextSyncToken: 'cursor-1',
      ),
      pushResponses: Queue<Object>.from([Exception('offline')]),
    );
    final syncEngine = engine(
      storage,
      transport,
      outbox: SyncOutbox(maxAttempts: 1, delay: (_) async {}),
    );
    await syncEngine.insert(const Task('local', 'queued'));

    await syncEngine.sync();
    await syncEngine.sync();

    expect(transport.pullTokens, ['', '']);
  });
}

class _BlockingSyncTransport extends FakeSyncTransport {
  _BlockingSyncTransport();

  final Completer<SyncBatch> _pullCompleter = Completer<SyncBatch>();
  int pullCount = 0;

  @override
  Future<SyncBatch> pull({required String lastSyncToken}) async {
    pullCount++;
    return _pullCompleter.future;
  }

  void completePull() {
    if (!_pullCompleter.isCompleted) {
      _pullCompleter.complete(const SyncBatch());
    }
  }
}

class _CursorTrackingTransport extends FakeSyncTransport {
  _CursorTrackingTransport({
    required this.batch,
    required this.pushResponses,
  });

  final SyncBatch batch;
  final Queue<Object> pushResponses;
  final List<String> pullTokens = [];

  @override
  Future<SyncBatch> pull({required String lastSyncToken}) async {
    pullTokens.add(lastSyncToken);
    return batch;
  }

  @override
  Future<SyncResult> push(List<SyncOperation> operations) async {
    final response = pushResponses.removeFirst();
    if (response is Exception) throw response;
    return response as SyncResult;
  }
}
