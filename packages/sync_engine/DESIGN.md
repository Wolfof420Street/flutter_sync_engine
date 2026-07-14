# Phase 2 design notes

## LWW frontier pruning

An LWW frontier entry is safe to prune once the vector clock acknowledged by
every known replica in a successful synchronization round-trip has advanced
past that entry's timestamp. At that point it cannot become concurrent with a
future write.

Pruning belongs after a successful `SyncEngine.sync()` pull/push round-trip,
because that is where the engine has fresh replica acknowledgements. Phase 2
provides only a maintenance hook: the persistent, per-replica acknowledgement
data required to implement this correctly arrives with the Drift adapter.
