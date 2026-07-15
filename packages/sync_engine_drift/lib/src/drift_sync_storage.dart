import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:sync_engine/sync_engine.dart';

import 'database.dart';

/// Drift storage using reject-on-dominance semantics: a causally stale save is
/// ignored so it cannot regress a newer durable value.
class DriftSyncStorage implements SyncStorage, SyncAcknowledgementStorage {
  DriftSyncStorage(this._database,
      {Map<Type, SyncAdapter<dynamic>> adapters = const {},
      Set<String> knownReplicas = const {}})
      : _adapters = Map<Type, SyncAdapter<dynamic>>.from(adapters),
        _knownReplicas = Set<String>.from(knownReplicas);

  final SyncDriftDatabase _database;
  final Map<Type, SyncAdapter<dynamic>> _adapters;
  final Set<String> _knownReplicas;

  void register<T>(SyncAdapter<T> adapter) => _adapters[T] = adapter;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> save<T>(
      String id, T entity, VectorClock clock, String nodeId) async {
    final adapter = _adapter<T>();
    final existing = await loadStored(adapter.modelType, id);
    await _saveByAdapter(
      adapter,
      id,
      entity as Object,
      clock,
      nodeId,
      adapter.fieldMetadataForWrite(
        entity,
        existing?.value as T?,
        existing?.fieldMetadata ?? const {},
        clock,
        nodeId,
      ),
    );
  }

  @override
  Future<T?> load<T>(String id) async {
    final adapter = _adapter<T>();
    final row = await _row(adapter.entityType, id);
    if (row == null || row.read<int>('deleted') == 1) return null;
    return adapter.fromJson(
        jsonDecode(row.read<String>('payload')) as Map<String, dynamic>);
  }

  @override
  Future<List<T>> loadAll<T>() async {
    final adapter = _adapter<T>();
    final rows = await _database.customSelect(
        'SELECT payload FROM sync_entity_table WHERE entity_type=? AND deleted=0',
        variables: [Variable<String>(adapter.entityType)]).get();
    return [
      for (final row in rows)
        adapter.fromJson(
            jsonDecode(row.read<String>('payload')) as Map<String, dynamic>)
    ];
  }

  @override
  Future<void> delete<T>(String id, VectorClock clock, String nodeId) async {
    final adapter = _adapter<T>();
    await _deleteByType(adapter.entityType, id, clock, nodeId);
  }

  @override
  Future<SyncStoredEntity<Object?>?> loadStored(Type type, String id) async {
    final adapter = _adapterByType(type);
    final row = await _row(adapter.entityType, id);
    if (row == null) return null;
    final deleted = row.read<int>('deleted') == 1;
    return SyncStoredEntity(
      value: deleted
          ? null
          : adapter.fromJson(
              jsonDecode(row.read<String>('payload')) as Map<String, dynamic>),
      clock: VectorClock.fromJson(
          jsonDecode(row.read<String>('vector_clock')) as Map<String, dynamic>),
      nodeId: row.read<String>('node_id'),
      deleted: deleted,
      fieldMetadata: _decodeMetadata(row.read<String>('field_metadata')),
    );
  }

  @override
  Future<void> saveStored(
      Type type,
      String id,
      Object entity,
      VectorClock clock,
      String nodeId,
      Map<String, FieldLwwMetadata> fieldMetadata) async {
    final adapter = _adapterByType(type);
    await _saveByAdapter(adapter, id, entity, clock, nodeId, fieldMetadata);
  }

  @override
  Future<void> deleteStored(
      Type type, String id, VectorClock clock, String nodeId,
      [Map<String, FieldLwwMetadata> fieldMetadata = const {}]) async {
    await _deleteByType(_adapterByType(type).entityType, id, clock, nodeId);
  }

  @override
  Stream<List<T>> watch<T>() {
    final adapter = _adapter<T>();
    return _database
        .customSelect(
            'SELECT payload FROM sync_entity_table WHERE entity_type=? AND deleted=0',
            variables: [Variable<String>(adapter.entityType)])
        .watch()
        .map((rows) => [
              for (final row in rows)
                adapter.fromJson(jsonDecode(row.read<String>('payload'))
                    as Map<String, dynamic>)
            ]);
  }

  @override
  Future<void> recordAcknowledgements(
      List<ReplicaAcknowledgement> acknowledgements) async {
    for (final ack in acknowledgements) {
      await _database.customStatement(
          'INSERT INTO replica_acknowledgements (entity_type,entity_id,node_id,acknowledged_clock) VALUES (?,?,?,?) ON CONFLICT(entity_type,entity_id,node_id) DO UPDATE SET acknowledged_clock=excluded.acknowledged_clock',
          [
            ack.entityType,
            ack.entityId,
            ack.nodeId,
            jsonEncode(ack.acknowledgedClock.toJson())
          ]);
    }
  }

  @override
  Future<void> pruneAcknowledgedFrontiers() async {
    if (_knownReplicas.isEmpty) return;
    final entries = await _database
        .customSelect('SELECT * FROM lww_frontier_entries')
        .get();
    final groups = <String, List<QueryRow>>{};
    for (final entry in entries) {
      groups
          .putIfAbsent(
              '${entry.read<String>('entity_type')}\u0000${entry.read<String>('entity_id')}',
              () => [])
          .add(entry);
    }
    for (final group in groups.values) {
      final type = group.first.read<String>('entity_type');
      final id = group.first.read<String>('entity_id');
      final winner = group
          .map((row) => row.read<String>('node_id'))
          .reduce(LWWRegister.winningNodeId);
      final acknowledgements = await _database.customSelect(
          'SELECT node_id, acknowledged_clock FROM replica_acknowledgements WHERE entity_type=? AND entity_id=?',
          variables: [Variable<String>(type), Variable<String>(id)]).get();
      final byNode = {
        for (final ack in acknowledgements)
          ack.read<String>('node_id'): VectorClock.fromJson(
              jsonDecode(ack.read<String>('acknowledged_clock'))
                  as Map<String, dynamic>)
      };
      for (final entry in group) {
        if (entry.read<String>('node_id') == winner) continue;
        final clock = VectorClock.fromJson(
            jsonDecode(entry.read<String>('timestamp'))
                as Map<String, dynamic>);
        if (_knownReplicas.every((node) {
          final acknowledged = byNode[node];
          return acknowledged != null &&
              (clock.happenedBefore(acknowledged) || clock == acknowledged);
        })) {
          await _database.customStatement(
              'DELETE FROM lww_frontier_entries WHERE entity_type=? AND entity_id=? AND node_id=?',
              [type, id, entry.read<String>('node_id')]);
        }
      }
    }
  }

  Future<void> persistFrontierEntry(String entityType, String entityId,
          String nodeId, VectorClock timestamp) =>
      _database.customStatement(
          'INSERT OR REPLACE INTO lww_frontier_entries (entity_type,entity_id,node_id,timestamp) VALUES (?,?,?,?)',
          [entityType, entityId, nodeId, jsonEncode(timestamp.toJson())]);

  Future<int> frontierSize(String entityType, String entityId) async =>
      (await _database.customSelect(
              'SELECT count(*) AS count FROM lww_frontier_entries WHERE entity_type=? AND entity_id=?',
              variables: [
            Variable<String>(entityType),
            Variable<String>(entityId)
          ]).getSingle())
          .read<int>('count');

  Future<Set<String>> frontierNodeIds(
          String entityType, String entityId) async =>
      (await _database.customSelect(
              'SELECT node_id FROM lww_frontier_entries WHERE entity_type=? AND entity_id=?',
              variables: [
            Variable<String>(entityType),
            Variable<String>(entityId)
          ]).get())
          .map((row) => row.read<String>('node_id'))
          .toSet();

  Future<QueryRow?> _row(String type, String id) async {
    final rows = await _database.customSelect(
        'SELECT * FROM sync_entity_table WHERE entity_type=? AND id=?',
        variables: [Variable<String>(type), Variable<String>(id)]).get();
    return rows.isEmpty ? null : rows.single;
  }

  SyncAdapter<T> _adapter<T>() {
    final adapter = _adapters[T];
    if (adapter == null) throw UnregisteredSyncTypeError(T);
    return adapter as SyncAdapter<T>;
  }

  SyncAdapter<dynamic> _adapterByType(Type type) {
    final adapter = _adapters[type];
    if (adapter == null) throw UnregisteredSyncTypeError(type);
    return adapter;
  }

  Future<void> _saveByAdapter(
      SyncAdapter<dynamic> adapter,
      String id,
      Object entity,
      VectorClock clock,
      String nodeId,
      Map<String, FieldLwwMetadata> fieldMetadata) async {
    final existing = await _row(adapter.entityType, id);
    if (existing != null &&
        VectorClock.fromJson(jsonDecode(existing.read<String>('vector_clock'))
                as Map<String, dynamic>)
            .happenedAfter(clock)) {
      return;
    }
    await _database.customStatement(
      'INSERT INTO sync_entity_table (entity_type,id,payload,vector_clock,field_metadata,node_id,deleted,last_modified) VALUES (?,?,?,?,?,?,0,strftime(\'%s\',\'now\')) '
      'ON CONFLICT(entity_type,id) DO UPDATE SET payload=excluded.payload,vector_clock=excluded.vector_clock,field_metadata=excluded.field_metadata,node_id=excluded.node_id,deleted=0,last_modified=excluded.last_modified',
      [
        adapter.entityType,
        id,
        jsonEncode(adapter.toJson(entity)),
        jsonEncode(clock.toJson()),
        _encodeMetadata(fieldMetadata),
        nodeId
      ],
    );
  }

  Future<void> _deleteByType(
          String entityType, String id, VectorClock clock, String nodeId) =>
      _database.customStatement(
        'INSERT INTO sync_entity_table (entity_type,id,payload,vector_clock,field_metadata,node_id,deleted,last_modified) VALUES (?,?,\'{}\',?,?,?,1,strftime(\'%s\',\'now\')) '
        'ON CONFLICT(entity_type,id) DO UPDATE SET vector_clock=excluded.vector_clock,field_metadata=excluded.field_metadata,node_id=excluded.node_id,deleted=1,last_modified=excluded.last_modified',
        [entityType, id, jsonEncode(clock.toJson()), '{}', nodeId],
      );

  Map<String, FieldLwwMetadata> _decodeMetadata(String json) {
    final values = jsonDecode(json) as Map<String, dynamic>;
    return values.map((key, value) => MapEntry(
        key, FieldLwwMetadata.fromJson(value as Map<String, dynamic>)));
  }

  String _encodeMetadata(Map<String, FieldLwwMetadata> metadata) =>
      jsonEncode(metadata.map((key, value) => MapEntry(key, value.toJson())));
}
