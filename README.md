# flutter_sync_engine

A backend-agnostic, CRDT-based offline-first synchronization toolkit for
Flutter. The repository is a Melos/Dart workspace; its first package,
`sync_engine`, is deliberately pure Dart and has no Flutter dependency.

## Status

Phase 1 implements immutable vector clocks and the G-Counter, G-Set, and
LWW-Register CRDTs, with randomized merge-law tests. Storage, transport,
code generation, Drift, and background sync are subsequent phases.

The LWW register resolves concurrent writes by lexicographically comparing
node IDs. This is deterministic but arbitrary: it is not a semantic conflict
resolution policy for every domain.

Encryption at rest and background sync are out of scope for the current MVP.
