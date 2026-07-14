# Architecture

`sync_engine` contains deterministic, immutable CRDT primitives only. It has
no Flutter imports, platform channels, persistence implementation, or network
client. Future storage and transport packages will depend on this package, not
the reverse.

Vector clocks establish causal ordering. Concurrent LWW writes are resolved
with an explicit lexicographic node-ID tie-breaker.
