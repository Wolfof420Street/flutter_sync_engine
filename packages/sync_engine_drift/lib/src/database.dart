import 'package:drift/drift.dart';

import 'schema.dart';

part 'database.g.dart';

/// Database containing the durable sync rows and replica acknowledgements.
@DriftDatabase(
    tables: [SyncEntityTable, ReplicaAcknowledgements, LwwFrontierEntries])
class SyncDriftDatabase extends _$SyncDriftDatabase {
  SyncDriftDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createOutboxTables(m.database);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            throw StateError(
              'sync_engine_drift schema version 2 requires a fresh local '
              'database because existing rows have no durable node_id. '
              'Delete the local database and let it be recreated.',
            );
          }
          if (from < 3) {
            await _createOutboxTables(m.database);
          }
        },
      );
}

Future<void> _createOutboxTables(GeneratedDatabase database) async {
  await database.customStatement(
    '''
CREATE TABLE IF NOT EXISTS sync_outbox_operations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  operation_kind TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  vector_clock TEXT NOT NULL,
  node_id TEXT NOT NULL,
  field_metadata TEXT NOT NULL,
  serialized_entity TEXT,
  attempts INTEGER NOT NULL DEFAULT 0,
  next_attempt_at INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  dead_letter INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
''',
  );
  await database.customStatement(
    '''
CREATE INDEX IF NOT EXISTS sync_outbox_operations_pending_idx
ON sync_outbox_operations(dead_letter, next_attempt_at, id)
''',
  );
}
