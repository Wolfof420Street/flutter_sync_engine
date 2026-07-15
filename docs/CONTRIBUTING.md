# Contributing

## Local workflow

Install Flutter and Dart, then activate `melos 2.9.0` and run `melos bootstrap`. Use `melos run analyze`,
`melos run test`, and `melos run generate` before opening a change.

Core CRDT code in `packages/sync_engine` must remain pure Dart. Do not import
Flutter or platform packages there.

## Generated sync models

Annotate a model with `@Syncable` and exactly one `String @Id()` field. Run
build_runner after changing an annotated model and include the generated source
in the change. Keep generated adapters on public `sync_engine` APIs only.

## Adding a CRDT strategy

1. Define the strategy in the pure-Dart core with unit and randomized law tests.
2. Add the annotation enum value and generator dispatch.
3. Define serialization and durable metadata requirements.
4. Add generated-fixture and two-replica convergence coverage.
5. Update `SYNC_PROTOCOL.md` and relevant migration documentation.

Avoid introducing a strategy that silently falls back to entity-wide LWW.

## Migrations and compatibility

Schema manifests support additive field names only. Review every generated
schema change. Do not add placeholder provenance for old rows: the documented
destructive reset boundary is safer than a fabricated LWW writer identity.
