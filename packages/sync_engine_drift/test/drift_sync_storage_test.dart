import 'package:drift/native.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:sync_engine_drift/sync_engine_drift.dart';
import 'package:test/test.dart';

import 'support/sqlite3_test_loader.dart';

class _Item {
  const _Item(this.id, this.value);
  final String id;
  final String value;
  @override
  bool operator ==(Object other) =>
      other is _Item && other.id == id && other.value == value;
  @override
  int get hashCode => Object.hash(id, value);
}

class _ItemAdapter implements SyncAdapter<_Item> {
  @override
  Type get modelType => _Item;
  @override
  String get entityType => 'item';
  @override
  String idOf(_Item entity) => entity.id;
  @override
  Map<String, dynamic> toJson(_Item entity) =>
      {'id': entity.id, 'value': entity.value};
  @override
  _Item fromJson(Map<String, dynamic> json) =>
      _Item(json['id'] as String, json['value'] as String);

  @override
  Map<String, FieldLwwMetadata> fieldMetadataForWrite(
          _Item entity,
          _Item? previous,
          Map<String, FieldLwwMetadata> previousMetadata,
          VectorClock clock,
          String nodeId) =>
      {
        'value': previous == null || previous.value != entity.value
            ? FieldLwwMetadata(timestamp: clock, nodeId: nodeId)
            : previousMetadata['value']!,
      };

  @override
  SyncMergeResult<_Item> merge(
      _Item local,
      _Item remote,
      VectorClock localClock,
      VectorClock remoteClock,
      String localNodeId,
      String remoteNodeId,
      Map<String, FieldLwwMetadata> localFieldMetadata,
      Map<String, FieldLwwMetadata> remoteFieldMetadata) {
    final winner = FieldLwwMetadata.winner(
        localFieldMetadata['value']!, remoteFieldMetadata['value']!);
    return SyncMergeResult(
      winner == localFieldMetadata['value']! ? local : remote,
      {'value': winner},
    );
  }
}

void main() {
  setUpAll(configureSqliteForTests);

  test('rejects a causally stale save instead of regressing durable state',
      () async {
    final database = SyncDriftDatabase(NativeDatabase.memory());
    final storage =
        DriftSyncStorage(database, adapters: {_Item: _ItemAdapter()});
    await storage.save(
        'one', const _Item('one', 'new'), VectorClock({'a': 2}), 'a');
    await storage.save(
        'one', const _Item('one', 'stale'), VectorClock({'a': 1}), 'a');
    expect(await storage.load<_Item>('one'), const _Item('one', 'new'));
    expect(storage, isA<SyncAcknowledgementStorage>());
    await database.close();
  });

  test('rejects an older delete instead of regressing durable state', () async {
    final database = SyncDriftDatabase(NativeDatabase.memory());
    final storage =
        DriftSyncStorage(database, adapters: {_Item: _ItemAdapter()});
    await storage.save(
        'one', const _Item('one', 'new'), VectorClock({'a': 2}), 'a');
    await storage.delete<_Item>('one', VectorClock({'a': 1}), 'a');
    expect(await storage.load<_Item>('one'), const _Item('one', 'new'));
    final stored = await storage.loadStored(_Item, 'one');
    expect(stored?.deleted, isFalse);
    await database.close();
  });

  test('accepts a newer delete and persists its tombstone', () async {
    final database = SyncDriftDatabase(NativeDatabase.memory());
    final storage =
        DriftSyncStorage(database, adapters: {_Item: _ItemAdapter()});
    await storage.save(
        'one', const _Item('one', 'old'), VectorClock({'a': 1}), 'a');
    await storage.delete<_Item>('one', VectorClock({'a': 2}), 'a');
    expect(await storage.load<_Item>('one'), isNull);
    final stored = await storage.loadStored(_Item, 'one');
    expect(stored?.deleted, isTrue);
    expect(stored?.clock, VectorClock({'a': 2}));
    await database.close();
  });

  test('equal-clock delete replaces the existing value', () async {
    final database = SyncDriftDatabase(NativeDatabase.memory());
    final storage =
        DriftSyncStorage(database, adapters: {_Item: _ItemAdapter()});
    final clock = VectorClock({'a': 1});
    await storage.save('one', const _Item('one', 'value'), clock, 'a');
    await storage.delete<_Item>('one', clock, 'a');
    expect(await storage.load<_Item>('one'), isNull);
    await database.close();
  });

  test('preserves non-empty tombstone field metadata', () async {
    final database = SyncDriftDatabase(NativeDatabase.memory());
    final storage =
        DriftSyncStorage(database, adapters: {_Item: _ItemAdapter()});
    final metadata = {
      'value': FieldLwwMetadata(timestamp: VectorClock({'a': 2}), nodeId: 'a')
    };
    await storage.deleteStored(
        _Item, 'one', VectorClock({'a': 2}), 'a', metadata);
    final stored = await storage.loadStored(_Item, 'one');
    expect(stored?.fieldMetadata, metadata);
    await database.close();
  });

  test('preserves empty tombstone field metadata', () async {
    final database = SyncDriftDatabase(NativeDatabase.memory());
    final storage =
        DriftSyncStorage(database, adapters: {_Item: _ItemAdapter()});
    await storage
        .deleteStored(_Item, 'one', VectorClock({'a': 1}), 'a', const {});
    final stored = await storage.loadStored(_Item, 'one');
    expect(stored?.fieldMetadata, isEmpty);
    await database.close();
  });

  test(
      'prunes a concurrent frontier only after the last configured replica acknowledges',
      () async {
    final database = SyncDriftDatabase(NativeDatabase.memory());
    final storage =
        DriftSyncStorage(database, knownReplicas: {'a', 'b', 'c', 'd'});
    for (final node in const ['a', 'b', 'c', 'd']) {
      await storage.persistFrontierEntry(
          'item', 'one', node, VectorClock({node: 1}));
    }
    for (final node in const ['a', 'b', 'c']) {
      await storage.recordAcknowledgements([
        ReplicaAcknowledgement(
            entityType: 'item',
            entityId: 'one',
            nodeId: node,
            acknowledgedClock: VectorClock({'a': 1, 'b': 1, 'c': 1, 'd': 1})),
      ]);
      await storage.pruneAcknowledgedFrontiers();
      expect(await storage.frontierSize('item', 'one'), 4);
    }
    await storage.recordAcknowledgements([
      ReplicaAcknowledgement(
          entityType: 'item',
          entityId: 'one',
          nodeId: 'd',
          acknowledgedClock: VectorClock({'a': 1, 'b': 1, 'c': 1, 'd': 1})),
    ]);
    await storage.pruneAcknowledgedFrontiers();
    expect(await storage.frontierSize('item', 'one'), 1);
    expect(await storage.frontierNodeIds('item', 'one'), {'d'});
    await database.close();
  });

  test('retains an entry when one replica has only a partial acknowledgement',
      () async {
    final database = SyncDriftDatabase(NativeDatabase.memory());
    final storage =
        DriftSyncStorage(database, knownReplicas: {'a', 'b', 'c', 'd'});
    for (final node in const ['a', 'b', 'c', 'd']) {
      await storage.persistFrontierEntry(
          'item', 'partial', node, VectorClock({node: 1}));
    }
    for (final node in const ['a', 'b', 'c']) {
      await storage.recordAcknowledgements([
        ReplicaAcknowledgement(
            entityType: 'item',
            entityId: 'partial',
            nodeId: node,
            acknowledgedClock: VectorClock({'a': 1, 'b': 1, 'c': 1, 'd': 1}))
      ]);
    }
    await storage.recordAcknowledgements([
      ReplicaAcknowledgement(
          entityType: 'item',
          entityId: 'partial',
          nodeId: 'd',
          acknowledgedClock: VectorClock({'a': 0, 'b': 1, 'c': 1, 'd': 1}))
    ]);
    await storage.pruneAcknowledgedFrontiers();
    expect(await storage.frontierNodeIds('item', 'partial'), contains('a'));
    expect(await storage.frontierSize('item', 'partial'), 2);
    await storage.recordAcknowledgements([
      ReplicaAcknowledgement(
          entityType: 'item',
          entityId: 'partial',
          nodeId: 'd',
          acknowledgedClock: VectorClock({'a': 1, 'b': 1, 'c': 1, 'd': 1}))
    ]);
    await storage.pruneAcknowledgedFrontiers();
    expect(await storage.frontierNodeIds('item', 'partial'), {'d'});
    await database.close();
  });

  test('supports save, load, loadAll, tombstone delete, and watch', () async {
    final database = SyncDriftDatabase(NativeDatabase.memory());
    final storage =
        DriftSyncStorage(database, adapters: {_Item: _ItemAdapter()});
    final watched = <List<_Item>>[];
    final subscription = storage.watch<_Item>().listen(watched.add);
    await storage.save(
        'one', const _Item('one', 'first'), VectorClock({'a': 1}), 'a');
    await storage.save(
        'one', const _Item('one', 'updated'), VectorClock({'a': 2}), 'a');
    expect(await storage.load<_Item>('one'), const _Item('one', 'updated'));
    expect(await storage.loadAll<_Item>(), [const _Item('one', 'updated')]);
    await storage.delete<_Item>('one', VectorClock({'a': 3}), 'a');
    expect(await storage.load<_Item>('one'), isNull);
    expect(await storage.loadAll<_Item>(), isEmpty);
    await Future<void>.delayed(Duration.zero);
    expect(watched, isNotEmpty);
    await subscription.cancel();
    await database.close();
  });
}
