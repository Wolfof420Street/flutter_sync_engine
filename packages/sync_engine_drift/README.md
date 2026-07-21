# sync_engine_drift

[![pub.dev](https://img.shields.io/pub/v/sync_engine_drift.svg)](https://pub.dev/packages/sync_engine_drift)

Drift persistence adapter for `sync_engine`. It provides `DriftSyncStorage`, a
`SyncStorage` implementation for optimistic local entities, tombstones, and
durable replica acknowledgements.

## Storage model

The adapter stores all synced entity types in a shared `sync_entity_table`:

- `entity_type` and `id` form the primary key;
- `payload` holds serialized domain JSON;
- `vector_clock` holds serialized causal metadata;
- `deleted` is the tombstone flag; and
- `last_modified` is an integer Unix timestamp.

It also persists `replica_acknowledgements` and `lww_frontier_entries`. A
causally stale `save` is rejected rather than overwriting a newer durable row.

`DriftSyncOutbox` stores pending operations in the same database. It persists
serialized payloads, retry counts, next-attempt timestamps, last errors, and
dead letters so queued work survives process restarts. Transport responses are
validated before an operation is removed or retried.

## Acknowledgement pruning

`DriftSyncStorage` implements `SyncAcknowledgementStorage`. Frontier entries
are pruned only when every member of the configured `knownReplicas` roster has
acknowledged a clock that causally dominates the individual entry. An empty
roster disables pruning: distinct acknowledgement rows alone are not a safe
definition of every replica that could still need the data.

The surviving concurrent value is selected by the shared
`LWWRegister.winningNodeId` comparator, so storage pruning and CRDT
materialization use the same deterministic tie-break rule.

## Drift generation and schema manifests

Enable the generator's Drift output in the consuming package's `build.yaml`:

```yaml
targets:
  $default:
    builders:
      sync_engine_generator|syncable:
        options:
          generate_drift_table: true
          schema_manifest: lib/sync_engine_schema.json
```

For a first build, temporarily set `bootstrap_schema: true`, then create and
review the checked-in baseline with `bootstrap_schema`. Later additive field
changes are reviewed through `update_schema`; removals and rename-shaped
changes fail generation.

```sh
dart run sync_engine_generator:bootstrap_schema lib/sync_engine_schema.json Task id,title
dart run sync_engine_generator:update_schema lib/sync_engine_schema.json Task id,title,completed
```

See [DESIGN.md](DESIGN.md) for the MVP migration boundary: validation is
additive-name-only, and type changes require an explicit application migration.
