# Building SyncForge with Codex

## Problem

Offline-first applications must handle concurrent writes, causal ordering,
retries, deletes, persistence and backend differences. A simple queue is not a
merge protocol, and a last-write-wins entity overwrite loses independent work.

## How Codex helped

Codex drafted CRDT scaffolding, randomized property tests, `build_runner`
fixtures, adapter boilerplate, demo applications, CI checks and release docs.
It also shortened feedback loops by surfacing failures in generated Drift code,
fixture setup, and demo widget flows.

## Human engineering decisions

- Keep the CRDT engine pure Dart so merge law tests run anywhere.
- Use vector clocks for causal ordering and per-field LWW metadata for
  independent concurrent changes.
- Keep persistence and transport behind `SyncStorage` and `SyncTransport`.
- Treat generated code as a draft until build output, tests and review agree.
- Reject unsafe schema provenance migrations rather than inventing a writer ID.

## Validation

The result is checked through 1,000-iteration CRDT merge-law tests, two-replica
convergence tests, stale-write and pruning tests, migration bootstrap/additive/
rename fixtures, generated-adapter tests, real HTTP task-manager coverage, and
an external consumer notes app. The conflict playground makes that validation
visible to a Build Week audience.
