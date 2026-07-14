# sync_engine

Pure-Dart, immutable CRDT primitives for `flutter_sync_engine`. It can be
tested with `dart test` and deliberately has no Flutter dependency.

## LWW conflict resolution

`LWWRegister` uses vector clocks for causal order. If two writes are
concurrent, it selects the value from the lexicographically greater node ID.
That rule is deterministic but arbitrary; applications needing domain-specific
resolution should provide it above this primitive.
