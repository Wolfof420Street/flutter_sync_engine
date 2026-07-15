import 'package:drift/drift.dart';

/// Base persisted shape for a synchronized entity.
///
/// Generated per-entity tables use the same columns; payload and clock are
/// JSON strings so domain serialization remains owned by generated adapters.
class SyncEntityTable extends Table {
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get id => text()();
  TextColumn get payload => text()();
  TextColumn get vectorClock => text().named('vector_clock')();
  TextColumn get fieldMetadata => text().named('field_metadata')();

  /// Durable provenance required for deterministic LWW tie-breaking.
  TextColumn get nodeId => text().named('node_id')();
  IntColumn get deleted => integer().withDefault(const Constant(0))();
  IntColumn get lastModified => integer()
      .named('last_modified')
      .withDefault(const CustomExpression<int>("strftime('%s','now')"))();

  @override
  Set<Column<Object>> get primaryKey => {entityType, id};
}

/// Per-entity, per-replica acknowledgement durable state.
@DataClassName('ReplicaAcknowledgementRow')
class ReplicaAcknowledgements extends Table {
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get nodeId => text().named('node_id')();
  TextColumn get acknowledgedClock => text().named('acknowledged_clock')();

  @override
  Set<Column<Object>> get primaryKey => {entityType, entityId, nodeId};
}

/// Persisted causally-undominated LWW candidates for safe acknowledgement pruning.
class LwwFrontierEntries extends Table {
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get nodeId => text().named('node_id')();
  TextColumn get timestamp => text()();

  @override
  Set<Column<Object>> get primaryKey => {entityType, entityId, nodeId};
}
