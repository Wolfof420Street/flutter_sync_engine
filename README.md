# SyncForge

**Production-grade offline synchronization for Flutter.**

Add `@Syncable`. Generate conflict resolution. Build offline-first apps.

> Demo video / GIF placeholder: run [`example/conflict_playground`](example/conflict_playground)
> to watch two offline devices make concurrent edits and converge through the
> real SyncForge engine.

## Why SyncForge?

Offline sync is not just retries. Two devices can change the same data while
disconnected, then reconnect in any order. SyncForge provides the parts Flutter
apps otherwise have to invent: vector clocks, CRDT merge laws, optimistic local
writes, durable tombstones, rollback, retries, and generated per-field merge
adapters.

```text
@Syncable model → generated SyncAdapter → SyncEngine
                                        ├── your SyncStorage (Drift, etc.)
                                        └── your SyncTransport (REST, etc.)
```

The pure-Dart core is backend-agnostic and has no Flutter dependency.

## Start in five minutes

```dart
@Syncable()
class Todo {
  const Todo({required this.id, required this.title});

  @Id()
  final String id;

  @ConflictStrategy(ConflictType.lastWriteWins)
  final String title;
}
```

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

```dart
final sync = SyncEngine(
  storage: storage,
  transport: transport,
  nodeId: 'device-a',
  adapters: {Todo: const TodoSyncAdapter()},
);
```

See [`example/minimal_app`](example/minimal_app) for the complete smallest
consumer and [`example/notes_app`](example/notes_app) for persisted notes.

## See the conflict, not just the code

[`example/conflict_playground`](example/conflict_playground) gives judges a
two-device visual: Device A writes `Buy milk` and a detail while offline;
Device B writes `Buy eggs`; reconnecting resolves the title deterministically
and preserves Device A's independent detail. The history comes from the real
`SyncEngine.conflicts` stream.

## Packages

- [`sync_engine`](packages/sync_engine): pure-Dart clocks, CRDTs and sync API.
- [`sync_engine_generator`](packages/sync_engine_generator): `build_runner`
  adapters, serializers and registry wiring.
- [`sync_engine_drift`](packages/sync_engine_drift): Drift storage, tombstones,
  acknowledgements and causally safe frontier pruning.

## CRDT choices

`GCounter` and `GSet` merge monotonically. LWW fields retain a concurrent
frontier for associative merges, then use a documented deterministic
lexicographic node-ID tie-break only when materializing a value. Generated
adapters resolve LWW **per field**, so unrelated concurrent edits survive.

Read the wire and merge details in [`docs/SYNC_PROTOCOL.md`](docs/SYNC_PROTOCOL.md).

## Built with Codex + GPT-5.6

Codex accelerated scaffolding, property-test generation, fixture construction,
adapter boilerplate, and CI/docs work. Humans led the architecture and reviewed
the correctness boundaries; randomized CRDT laws, convergence tests, migration
fixtures and an external consumer app verify the result. See
[`docs/CODEX_JOURNEY.md`](docs/CODEX_JOURNEY.md).

## Development

```sh
dart pub global activate melos 2.9.0
melos bootstrap
melos run generate
melos run analyze
melos run test
```

## MVP boundaries

Encryption at rest and background sync are out of scope. Drift schema validation
is additive-name-only; schema v2 requires a fresh local database. See
[`packages/sync_engine_drift/DESIGN.md`](packages/sync_engine_drift/DESIGN.md).
