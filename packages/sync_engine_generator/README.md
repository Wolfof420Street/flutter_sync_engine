# sync_engine_generator

[![pub.dev](https://img.shields.io/pub/v/sync_engine_generator.svg)](https://pub.dev/packages/sync_engine_generator)

`build_runner` generator for `@Syncable` entities. It emits sync models,
serializers, CRDT-backed adapters, and registration helpers for `sync_engine`.

## Getting started

In a Flutter application, add the runtime package and the generator as a
development dependency:

```sh
flutter pub add sync_engine
flutter pub add --dev build_runner sync_engine_generator
```

Put the annotated model in its own library and include the generated part:

```dart
import 'package:sync_engine/sync_engine.dart';

part 'task.sync.dart';

@Syncable()
class Task {
  const Task({required this.id, required this.title});

  @Id()
  final String id;

  @ConflictStrategy(ConflictType.lastWriteWins)
  final String title;
}
```

The `part 'task.sync.dart';` directive is required. Create `build.yaml` at
the application root so the builder runs for the model:

```yaml
targets:
  $default:
    builders:
      sync_engine_generator|syncable:
        generate_for:
          - lib/**.dart
```

Generate the adapter with:

```sh
dart run build_runner build --delete-conflicting-outputs
```

The build creates `TaskSyncAdapter`, which can be passed to
`SyncEngine(adapters: {Task: const TaskSyncAdapter()})`. The engine still
requires application-provided `SyncStorage` and `SyncTransport`
implementations; [`sync_engine_drift`](https://pub.dev/packages/sync_engine_drift)
provides durable storage.

Add this to a consuming package's `build.yaml`:

```yaml
targets:
  $default:
    builders:
      sync_engine_generator|syncable:
        options:
          generate_drift_table: true # validate schema and emit an optional Drift table declaration
          schema_manifest: lib/sync_engine_schema.json # checked in; additive-only baseline
        generate_for:
          - lib/**.dart
```

For the first Drift build only, set `bootstrap_schema: true`, then create and
commit the baseline before turning it off:

```sh
dart run sync_engine_generator:bootstrap_schema lib/sync_engine_schema.json Task id,title,tags
```

Run the command once for each `@Syncable` type; it preserves existing entries
and rejects a duplicate type baseline.

After adding fields, update the reviewed manifest explicitly. Generation never
rewrites the checked-in baseline automatically:

```sh
dart run sync_engine_generator:update_schema lib/sync_engine_schema.json Task id,title,tags,completed
```

The command accepts additive field sets only; a removed or renamed baseline
field is rejected.

The generated Drift table is an application-side declaration for consumers
that want a typed table for their own queries. It is not the runtime table used
by `sync_engine_drift`, which always persists synchronized entities in its
shared `sync_entity_table`. Register generated tables in the consuming
application's own `@DriftDatabase` if needed.

If a field uses `@ConflictStrategy(ConflictType.custom)`, generation fails
explicitly. That unsupported merge path no longer defers to a runtime crash.
