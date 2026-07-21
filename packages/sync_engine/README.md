# sync_engine

[![pub.dev](https://img.shields.io/pub/v/sync_engine.svg)](https://pub.dev/packages/sync_engine)

Pure-Dart, immutable CRDT primitives for `flutter_sync_engine`. It can be
tested with `dart test` and deliberately has no Flutter dependency.

## LWW conflict resolution

`LWWRegister` uses vector clocks for causal order. If two writes are
concurrent, it selects the value from the lexicographically greater node ID.
That rule is deterministic but arbitrary; applications needing domain-specific
resolution should provide it above this primitive.

`SyncEngine` serializes sync cycles, validates transport acknowledgements, and
keeps the outbox cursor from advancing when a push fails. Durable persistence
is provided by `sync_engine_drift`; the core package ships the outbox contract
and in-memory implementation.
