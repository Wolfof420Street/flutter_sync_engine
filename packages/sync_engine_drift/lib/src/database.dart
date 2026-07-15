import 'package:drift/drift.dart';

import 'schema.dart';

part 'database.g.dart';

/// Database containing the durable sync rows and replica acknowledgements.
@DriftDatabase(tables: [SyncEntityTable, ReplicaAcknowledgements, LwwFrontierEntries])
class SyncDriftDatabase extends _$SyncDriftDatabase {
  SyncDriftDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (m) => m.createAll());
}
