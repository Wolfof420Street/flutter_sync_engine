# sync_engine_drift

[![pub.dev](https://img.shields.io/pub/v/sync_engine_drift.svg)](https://pub.dev/packages/sync_engine_drift)

Drift persistence adapter for `sync_engine`. It provides `DriftSyncStorage`, a
`SyncStorage` implementation for optimistic local entities, tombstones, and
durable replica acknowledgements.

## Getting started

Add the runtime, Drift adapter, generator, and build tools to a Flutter
application:

```sh
flutter pub add sync_engine sync_engine_drift drift sqlite3_flutter_libs
flutter pub add --dev build_runner sync_engine_generator drift_dev
```

Generate an adapter using the setup in the
[`sync_engine_generator` README](https://pub.dev/packages/sync_engine_generator),
then create the database and storage:

```dart
import 'package:drift/native.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:sync_engine_drift/sync_engine_drift.dart';

final database = SyncDriftDatabase(NativeDatabase.memory());
final storage = DriftSyncStorage(
  database,
  adapters: {Task: const TaskSyncAdapter()},
);

final sync = SyncEngine(
  storage: storage,
  transport: transport,
  nodeId: 'device-a',
  adapters: {Task: const TaskSyncAdapter()},
);

await storage.initialize();
await sync.insert(const Task(id: 'task-1', title: 'Sync me'));
```

`NativeDatabase.memory()` is useful for a smoke test. For production, pass a
file-backed Drift executor so the database survives process restarts, and call
`await database.close()` during application shutdown. The generated adapter
must be registered in both places when using `DriftSyncStorage` and
`SyncEngine`.

## Storage model

The adapter stores all synced entity types in a shared `sync_entity_table`:

- `entity_type` and `id` form the primary key;
- `payload` holds serialized domain JSON;
- `vector_clock` holds serialized causal metadata;
- `deleted` is the tombstone flag; and
- `last_modified` is an integer Unix timestamp.

It also persists `replica_acknowledgements` and `lww_frontier_entries`. A
causally stale saves and deletes are rejected rather than overwriting a newer
durable row.

The entity write path stores one materialized winner per LWW field. Frontier
rows are an application-managed acknowledgement-pruning hook; ordinary saves,
updates, merges, and deletes do not create them automatically. This keeps the
storage model aligned with the MVP contract documented in [DESIGN.md](DESIGN.md),
which does not persist multi-way LWW frontiers.

`DriftSyncOutbox` stores pending operations in the same database. It persists
serialized payloads, retry counts, next-attempt timestamps, last errors, and
dead letters so queued work survives process restarts. Transport responses are
validated before an operation is removed or retried.

## Acknowledgement pruning

`DriftSyncStorage` implements `SyncAcknowledgementStorage`. Frontier entries
are pruned only when every member of the configured `knownReplicas` roster has
acknowledged a clock that causally dominates the individual entry. An empty
roster disables pruning: distinct acknowledgement rows alone are not a safe
definition of every replica that could still need the data.

The surviving concurrent value is selected by the shared
`LWWRegister.winningNodeId` comparator, so storage pruning and CRDT
materialization use the same deterministic tie-break rule.

## Drift generation and schema manifests

Enable the generator's Drift schema validation and optional table declaration in
the consuming package's `build.yaml`:

```yaml
targets:
  $default:
    builders:
      sync_engine_generator|syncable:
        options:
          generate_drift_table: true
          schema_manifest: lib/sync_engine_schema.json
```

Generated tables are application-side Drift declarations. `DriftSyncStorage`
continues to use the shared `sync_entity_table`, so generated tables are not
registered by `SyncDriftDatabase` or used for synchronization automatically.
Applications that need the declarations must register them in their own Drift
database.

For a first build, temporarily set `bootstrap_schema: true`, then create and
review the checked-in baseline with `bootstrap_schema`. Later additive field
changes are reviewed through `update_schema`; removals and rename-shaped
changes fail generation.

```sh
dart run sync_engine_generator:bootstrap_schema lib/sync_engine_schema.json Task id,title
dart run sync_engine_generator:update_schema lib/sync_engine_schema.json Task id,title,completed
```

See [DESIGN.md](DESIGN.md) for the MVP migration boundary: validation is
additive-name-only, and type changes require an explicit application migration.
