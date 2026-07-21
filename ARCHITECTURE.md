# Architecture

`sync_engine` is pure Dart and owns no Flutter imports, platform channels,
database implementation, or network client. Adapters depend on the core; the
core never depends on adapters.

```text
Flutter app / generated adapters
            |
            v
       SyncEngine + SyncOutbox
         |              |
         v              v
    SyncStorage     SyncTransport
         |              |
         v              v
 DriftSyncStorage    REST / GraphQL / other backend
```

Vector clocks establish causal ordering. G-Counters and G-Sets merge by their
standard grow-only rules. LWW registers retain concurrent frontiers during
merge and materialize one deterministic winner with the lexicographically
greatest node ID.

Sync execution is serialized. The engine coalesces concurrent `sync()` calls,
validates transport acknowledgements, and only advances the local sync token
when a cycle completes without introducing new failures.

Generated adapters map `@Syncable` types to serializers and `SyncAdapter<T>`
implementations. `SyncEngine` fails clearly for an unregistered type instead of
accepting an unsafe generic cast.

`DriftSyncStorage` persists entity payloads, vector clocks, tombstones, replica
acknowledgements, and LWW frontier entries. It prunes a frontier entry only
after every configured known replica causally acknowledges it. A static
`knownReplicas` roster is intentional: acknowledgement rows seen so far cannot
prove every possible replica has observed an entry.

`DriftSyncOutbox` shares the same Drift database and persists queued
operations, retry counters, next-attempt timestamps, last errors, and dead
letters. Durable queue recovery uses the serialized entity payload captured by
generated adapters, so restart safety does not depend on in-memory domain
objects.

The task-manager example is intentionally a demo boundary: a Flutter client
uses HTTP to a separate in-memory Shelf process. It is not a production server.
