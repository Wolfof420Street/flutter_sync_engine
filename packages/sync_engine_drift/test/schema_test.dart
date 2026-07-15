import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sync_engine_drift/sync_engine_drift.dart';
import 'package:test/test.dart';

void main() {
  test(
      'sync entity schema exposes required columns and integer Unix-time default',
      () async {
    final database = SyncDriftDatabase(NativeDatabase.memory());
    final table = database.syncEntityTable;
    expect(table.primaryKey, {table.entityType, table.id});
    expect(table.id, isA<Column<String>>());
    expect(table.payload, isA<Column<String>>());
    expect(table.vectorClock, isA<Column<String>>());
    expect(table.deleted, isA<Column<int>>());
    expect(table.lastModified, isA<Column<int>>());
    expect(table.lastModified.defaultValue, isA<CustomExpression<int>>());
    await database.close();
  });

  test('acknowledgements use a three-column composite primary key', () async {
    final database = SyncDriftDatabase(NativeDatabase.memory());
    final table = database.replicaAcknowledgements;
    expect(table.primaryKey, {table.entityType, table.entityId, table.nodeId});
    await database.close();
  });
}
