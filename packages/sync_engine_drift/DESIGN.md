# Migration limitations

Phase 4 migration validation is additive-name-only: a checked-in manifest
prevents removed or renamed fields from silently passing generation. Field type
changes are out of MVP scope and are not automatically migrated; applications
must introduce a new field and perform an explicit data migration instead.
