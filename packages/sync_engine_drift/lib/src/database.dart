import 'package:drift/drift.dart';

import 'schema.dart';

part 'database.g.dart';

/// Database containing the durable sync rows and replica acknowledgements.
@DriftDatabase(
    tables: [SyncEntityTable, ReplicaAcknowledgements, LwwFrontierEntries])
class SyncDriftDatabase extends _$SyncDriftDatabase {
  SyncDriftDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            throw StateError(
              'sync_engine_drift schema version 2 requires a fresh local '
              'database because existing rows have no durable node_id. '
              'Delete the local database and let it be recreated.',
            );
          }
        },
      );
}
