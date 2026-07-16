# SyncForge

> Production-grade offline synchronization for Flutter.

SyncForge is a backend-agnostic offline synchronization framework for Flutter applications. It combines CRDT-based conflict resolution, vector clocks, optimistic local updates, code generation, and pluggable storage and transport adapters to simplify building resilient offline-first applications.

The synchronization engine is implemented in pure Dart, making it portable, testable, and independent of Flutter.

---

## Features

- Offline-first architecture
- Pure Dart CRDT engine
- Vector clock–based causal ordering
- Per-field conflict resolution
- Optimistic writes with automatic rollback
- Durable outbox with retry and dead-letter handling
- Tombstone-based deletion support
- Annotation-driven code generation
- Drift storage adapter
- Backend-agnostic transport abstraction
- Comprehensive property-based and convergence testing

---

## Architecture

```text
                    @Syncable Models
                           │
                           ▼
                 Generated Sync Adapters
                           │
                           ▼
                      SyncEngine
                    /            \
                   /              \
          SyncStorage        SyncTransport
         (Drift, etc.)      (REST, GraphQL, ...)
```

SyncForge separates synchronization logic from storage and networking, allowing applications to integrate with existing backends without changing the synchronization engine.

---

## Quick Start

Define a synchronizable model:

```dart
@Syncable()
class Todo {
  const Todo({
    required this.id,
    required this.title,
  });

  @Id()
  final String id;

  @ConflictStrategy(ConflictType.lastWriteWins)
  final String title;
}
```

Generate the synchronization code:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Create a `SyncEngine` instance:

```dart
final sync = SyncEngine(
  storage: storage,
  transport: transport,
  nodeId: "device-a",
  adapters: {
    Todo: const TodoSyncAdapter(),
  },
);
```

---

## Packages

### `sync_engine`

The core synchronization library implemented in pure Dart.

Includes:

- Vector clocks
- CRDT implementations
- Synchronization protocol
- Optimistic write pipeline
- Conflict resolution
- Public synchronization API

---

### `sync_engine_generator`

Code generation using `build_runner`.

Generates:

- Sync adapters
- Serializers
- Merge logic
- Adapter registry

---

### `sync_engine_drift`

A production-ready Drift storage implementation featuring:

- Durable persistence
- Tombstones
- Acknowledgements
- Frontier pruning
- Schema versioning

---

## Examples

The repository includes several example applications.

| Example | Description |
|---------|-------------|
| `minimal_app` | Smallest possible integration |
| `notes_app` | Persistent offline note-taking application |
| `task_manager` | Full-featured synchronization example |
| `conflict_playground` | Interactive visualization of concurrent conflict resolution |

---

## Conflict Resolution

SyncForge combines multiple conflict-resolution strategies.

- **Vector clocks** provide causal ordering.
- **Per-field Last-Write-Wins (LWW)** resolves concurrent edits independently for each field.
- **GCounter** provides monotonic distributed counters.
- **GSet** provides grow-only replicated sets.
- **Tombstones** ensure deletes converge correctly across replicas.

This design allows unrelated concurrent edits to be preserved while maintaining deterministic convergence.

Further details are available in:

- `docs/SYNC_PROTOCOL.md`
- `packages/sync_engine_drift/DESIGN.md`

---

## Testing

The project includes extensive automated verification.

- Unit tests
- Integration tests
- Property-based CRDT verification
- Replica convergence testing
- Generator fixture validation
- Widget tests
- External consumer integration tests

Randomized property tests verify CRDT correctness across thousands of merge scenarios.

---

## Development

```bash
dart pub global activate melos 2.9.0

melos bootstrap
melos run generate
melos run analyze
melos run test
```

---

## Project Status

SyncForge is currently under active development.

Current capabilities include:

- Pure Dart synchronization engine
- Drift persistence
- Annotation-based code generation
- REST-style transport abstraction
- External consumer validation

Future work includes additional storage adapters, transport integrations, background synchronization, and encryption support.

---

## Documentation

- `docs/SYNC_PROTOCOL.md` — Synchronization protocol specification
- `ARCHITECTURE.md` — System architecture
- `docs/CONTRIBUTING.md` — Contribution guidelines
- `docs/RELEASE_CHECKLIST.md` — Release process
- `packages/sync_engine_drift/DESIGN.md` — Drift implementation details

---

## License

Released under the MIT License.
