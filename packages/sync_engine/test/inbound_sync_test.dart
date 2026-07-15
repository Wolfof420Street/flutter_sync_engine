import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

import 'fakes.dart';

class _InboundTransport extends FakeSyncTransport {
  _InboundTransport(this.batch);

  SyncBatch batch;

  @override
  Future<SyncBatch> pull({required String lastSyncToken}) async => batch;
}

SyncEngine _engine(
        FakeSyncStorage storage, SyncTransport transport, String nodeId) =>
    SyncEngine(
      storage: storage,
      transport: transport,
      nodeId: nodeId,
      adapters: {Task: TaskAdapter()},
    );

Map<String, FieldLwwMetadata> _metadata(
        Map<String, int> clock, String nodeId) =>
    {'title': FieldLwwMetadata(timestamp: VectorClock(clock), nodeId: nodeId)};

void main() {
  test('sequential local edits increment the persisted causal clock', () async {
    final storage = FakeSyncStorage();
    final engine = _engine(storage, FakeSyncTransport(), 'a');
    await engine.insert(const Task('task', 'first'));
    final first = await storage.loadStored(Task, 'task');
    await engine.update(const Task('task', 'second'));
    final second = await storage.loadStored(Task, 'task');

    expect(first!.clock, VectorClock({'a': 1}));
    expect(second!.clock, VectorClock({'a': 2}));
    expect(first.clock.happenedBefore(second.clock), isTrue);
  });

  test('inbound concurrent values use adapter merge dispatch', () async {
    final storage = FakeSyncStorage();
    await storage.saveStored(Task, 'task', const Task('task', 'local'),
        VectorClock({'a': 1}), 'a', _metadata({'a': 1}, 'a'));
    final transport = _InboundTransport(SyncBatch(operations: [
      UpdateOperation(
        entityType: 'task',
        entityId: 'task',
        vectorClock: VectorClock({'b': 1}),
        nodeId: 'b',
        fieldMetadata: _metadata({'b': 1}, 'b'),
        entity: const Task('task', 'remote'),
      ),
    ]));
    final engine = _engine(storage, transport, 'a');
    await engine.sync();

    expect(await storage.load<Task>('task'), const Task('task', 'remote'));
    expect((await storage.loadStored(Task, 'task'))!.clock,
        VectorClock({'a': 1, 'b': 1}));
  });

  test('concurrent update versus delete keeps the tombstone', () async {
    final storage = FakeSyncStorage();
    await storage.saveStored(Task, 'task', const Task('task', 'update'),
        VectorClock({'a': 1}), 'a', _metadata({'a': 1}, 'a'));
    final engine = _engine(
      storage,
      _InboundTransport(SyncBatch(operations: [
        DeleteOperation(
          entityType: 'task',
          entityId: 'task',
          vectorClock: VectorClock({'b': 1}),
          nodeId: 'b',
        ),
      ])),
      'a',
    );
    await engine.sync();

    final state = await storage.loadStored(Task, 'task');
    expect(state!.deleted, isTrue);
    expect(state.clock, VectorClock({'a': 1, 'b': 1}));
  });

  test('causally later update resurrects a tombstone', () async {
    final storage = FakeSyncStorage();
    await storage.deleteStored(Task, 'task', VectorClock({'a': 1}), 'a');
    final engine = _engine(
      storage,
      _InboundTransport(SyncBatch(operations: [
        UpdateOperation(
          entityType: 'task',
          entityId: 'task',
          vectorClock: VectorClock({'a': 1, 'b': 1}),
          nodeId: 'b',
          entity: const Task('task', 'resurrected'),
        ),
      ])),
      'a',
    );
    await engine.sync();

    expect(await storage.load<Task>('task'), const Task('task', 'resurrected'));
  });

  test('causally later delete wins over an update', () async {
    final storage = FakeSyncStorage();
    await storage.saveStored(Task, 'task', const Task('task', 'update'),
        VectorClock({'a': 1}), 'a', _metadata({'a': 1}, 'a'));
    final engine = _engine(
      storage,
      _InboundTransport(SyncBatch(operations: [
        DeleteOperation(
          entityType: 'task',
          entityId: 'task',
          vectorClock: VectorClock({'a': 1, 'b': 1}),
          nodeId: 'b',
        ),
      ])),
      'a',
    );
    await engine.sync();

    expect((await storage.loadStored(Task, 'task'))!.deleted, isTrue);
  });
}
