# Migration limitations

Phase 4 migration validation is additive-name-only: a checked-in manifest
prevents removed or renamed fields from silently passing generation. Field type
changes are out of MVP scope and are not automatically migrated; applications
must introduce a new field and perform an explicit data migration instead.

## Durable writer identity is a breaking schema boundary

The next schema version introduces a required `node_id` for every persisted
sync write. Local databases created by an earlier version cannot be migrated
safely: their rows record a vector clock but not the identity of the replica
that wrote the payload. A placeholder would falsely claim a real writer and
would participate in future LWW lexicographic tie-breaks.

That same version also adds required per-field LWW metadata. It records the
timestamp and node identity for each current single field winner; the payload
continues to hold the corresponding field value. This is deliberately
single-winner-per-field, not a persisted 3+-way concurrent frontier. G-Counter,
G-Set, and custom fields do not receive this metadata.

There is deliberately no automatic backfill or alternate legacy tie-break
rule. Upgrading from a database without durable `node_id` requires discarding
the local database and allowing it to be recreated. This is an explicit
pre-1.0/MVP limitation; it must be enforced as a destructive schema boundary,
not silently hidden by an in-place migration.
