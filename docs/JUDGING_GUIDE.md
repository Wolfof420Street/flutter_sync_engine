# SyncForge judging guide

**Suggested evaluation time: 8–10 minutes.**

## Start here

1. Read the root [README](../README.md) (1 minute).
2. Run the [Conflict Playground](../example/conflict_playground) (3 minutes).
3. Inspect the [minimal external consumer](../example/minimal_app) (2 minutes).
4. Run the [task manager](../example/task_manager) for optimistic/offline HTTP
   behavior (2 minutes).
5. Read [CODEX_JOURNEY.md](CODEX_JOURNEY.md) and
   [SYNC_PROTOCOL.md](SYNC_PROTOCOL.md) for implementation evidence.

## Architecture

```text
Annotated Flutter model
        ↓ build_runner
Generated adapter + serializer + per-field metadata
        ↓
Pure-Dart SyncEngine / vector clocks / CRDTs
        ↓                         ↓
SyncStorage (Drift)        SyncTransport (REST/Shelf today)
```

## Key innovations

- Pure-Dart CRDT core: no Flutter dependency in merge logic.
- Frontier-preserving LWW merge: associative and deterministic under concurrent
  writes.
- Generated **field-level** metadata: unrelated concurrent edits survive;
  SyncForge does not choose one whole-entity winner.
- Optimistic writes with rollback, retries, dead letters and observable
  conflicts.
- Drift tombstones, causal stale-write protection, acknowledgements and safe
  frontier pruning.
- Consumer proof: notes app, minimal app and visual two-device playground use
  public APIs rather than package internals.

## Run the demos

```sh
cd example/conflict_playground
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

For the smallest integration, open `example/minimal_app`. For the HTTP-backed
demo, follow `example/task_manager/README.md`.

## Evidence to inspect

- `packages/sync_engine/test/crdt_property_test.dart` — randomized merge laws.
- `packages/sync_engine_drift/test/integration/replica_convergence_test.dart`
  — two-replica field-level convergence.
- `packages/sync_engine_generator/test/drift_migration_fixture_test.dart` —
  bootstrap/additive/rename migration behavior.
- `docs/CODEX_JOURNEY.md` — Codex acceleration and human review boundaries.
