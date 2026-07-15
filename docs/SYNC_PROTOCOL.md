# Sync protocol

`sync_engine` is backend agnostic. A `SyncTransport` maps the protocol below
to REST, GraphQL, Supabase, or another backend. Payload serialization is owned
by the generated `SyncAdapter`.

## Operations

Every write is an insert, update, or delete operation with an entity clock and
the writer's node id. Updates also carry field-local LWW metadata.

```json
{
  "kind": "update",
  "entityType": "task",
  "entityId": "123",
  "clock": {"deviceA": 4, "deviceB": 2},
  "nodeId": "deviceA",
  "fieldMetadata": {
    "title": {
      "timestamp": {"deviceA": 4, "deviceB": 2},
      "nodeId": "deviceA"
    }
  },
  "entity": {"id": "123", "title": "Draft"}
}
```

The exact JSON property names are transport-defined, but all information above
must survive a push/pull round trip. Generated serializers provide envelope
helpers for field metadata.

## Causality and concurrent writes

Entity vector clocks determine whether one operation happened before another,
or whether they are concurrent. A causally newer entity replaces an older
entity. Concurrent updates are merged by the generated adapter:

- `lastWriteWins` fields independently select a winner by their own timestamp
  and node id. The node id comparison is deterministic and uses
  `LWWRegister.winningNodeId`.
- `growOnlyCounter` fields merge by per-node maximum.
- `growOnlySet` fields merge by union.
- `custom` fields require application-supplied merge behavior.

LWW persistence retains one winner per field. It does not persist a multi-value
frontier for three-or-more concurrent field updates.

## Tombstones

Deletes are tombstones. A delete causally after an update wins; an update
causally after a delete may resurrect the entity. For concurrent update/delete,
the MVP policy is delete-wins to avoid surprising resurrection of deleted data.

## Retries and failures

`SyncOutbox` retries transient push failures with exponential backoff: two
seconds initially, capped at sixty seconds. After eight attempts by default,
the operation moves to the dead-letter list and emits a `SyncFailure`. Server
rejections emit a rollback/conflict event so the UI can explain the change.

## Acknowledgements and pruning

Pull responses may include per-replica acknowledgement clocks. A storage
adapter implementing `SyncAcknowledgementStorage` records them. Drift pruning
removes a non-winning frontier entry only when every configured known replica
has acknowledged a clock that causally dominates that entry.

The complete replica set is configured by the Drift adapter. Dynamic membership
is out of scope for the MVP; do not treat merely observed acknowledgements as a
complete replica universe.

## Security boundary

The protocol contains application payloads and metadata in plaintext. Encryption
at rest is the responsibility of a storage adapter; encryption in transit is
the responsibility of the selected transport. Applications should authenticate
operations and validate backend authorization before accepting a push.
