# sync_engine_generator

`build_runner` generator for `@Syncable` entities. It emits sync models,
serializers, CRDT-backed adapters, and registration helpers for `sync_engine`.

Add this to a consuming package's `build.yaml`:

```yaml
targets:
  $default:
    builders:
      sync_engine_generator|syncable:
        generate_for:
          - lib/**.dart
```
