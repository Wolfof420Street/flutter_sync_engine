# Changelog

## Unreleased

- Reject causally stale Drift deletes and preserve tombstone field metadata.
- Document the shared Drift runtime table and application-managed frontier hook.
- Validate all maintained examples and valid generator fixtures in CI.
- Establish the Dart workspace and add the pure-Dart `sync_engine` package.
- Implement Phase 1 vector clocks and CRDT primitives with randomized merge-law tests.
- Serialize sync cycles, validate transport acknowledgements, and prevent premature cursor advancement.
- Add durable Drift-backed outbox persistence with retry metadata, dead letters, and restart recovery.
- Reject `ConflictType.custom` at generation time instead of allowing runtime crashes.
