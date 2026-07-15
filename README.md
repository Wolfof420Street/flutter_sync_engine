# flutter_sync_engine

Backend-agnostic, CRDT-based building blocks for offline-first Flutter apps.
The pure-Dart core provides vector clocks, CRDTs, optimistic synchronization,
retry/dead-letter handling, and pluggable storage/transport contracts.

## Packages

- `packages/sync_engine` — pure-Dart CRDTs and sync protocol.
- `packages/sync_engine_generator` — `@Syncable` build-runner adapters,
  serializers, registry wiring, and optional Drift tables.
- `packages/sync_engine_drift` — Drift persistence, tombstones, acknowledgements,
  and causally safe LWW frontier pruning.
- `example/task_manager` — Flutter demo with offline simulation and a synthetic
  Shelf HTTP server.

## Key behavior

- Core CRDT code has zero Flutter dependencies and is tested with `dart test`.
- LWW concurrent writes use a deterministic but arbitrary lexicographic node-ID
  tie-breaker. Teams should choose a domain-specific strategy where needed.
- `SyncEngine` requires a registered generated adapter for each domain type.
- Outbox retries use exponential backoff and expose permanent failures through
  dead letters/conflict events.

## Development

```sh
dart pub global activate melos
melos bootstrap
```

Run package checks with `dart analyze`/`dart test`, or use the GitHub Actions
workflow. The task-manager example has its own setup instructions in
[`example/task_manager/README.md`](example/task_manager/README.md).

## MVP boundaries

Encryption at rest and background sync are out of scope. Drift schema validation
is additive-name-only; see `packages/sync_engine_drift/DESIGN.md` for details.
