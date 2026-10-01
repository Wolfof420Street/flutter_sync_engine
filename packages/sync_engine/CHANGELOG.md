# Changelog

## 0.1.1

- Expand onboarding documentation with hosted installation, code generation,
  `SyncEngine` setup, and storage guidance.

## Unreleased

- Serialize sync execution, coalesce concurrent sync calls, and gate cursor advancement on successful cycles.
- Preserve serialized queued payloads so durable outboxes can recover transport-ready operations after restart.

## 0.1.0

- Add immutable vector clocks, G-Counter, G-Set, and LWW-Register CRDTs.
