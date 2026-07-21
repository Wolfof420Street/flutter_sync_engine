# Changelog

## Unreleased

- Establish the Dart workspace and add the pure-Dart `sync_engine` package.
- Implement Phase 1 vector clocks and CRDT primitives with randomized merge-law tests.
- Serialize sync cycles, validate transport acknowledgements, and prevent premature cursor advancement.
- Add durable Drift-backed outbox persistence with retry metadata, dead letters, and restart recovery.
- Reject `ConflictType.custom` at generation time instead of allowing runtime crashes.
