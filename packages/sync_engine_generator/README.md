# sync_engine_generator

[![pub.dev](https://img.shields.io/pub/v/sync_engine_generator.svg)](https://pub.dev/packages/sync_engine_generator)

`build_runner` generator for `@Syncable` entities. It emits sync models,
serializers, CRDT-backed adapters, and registration helpers for `sync_engine`.

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
