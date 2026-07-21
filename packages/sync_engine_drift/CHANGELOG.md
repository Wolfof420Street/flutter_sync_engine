# Changelog

## Unreleased

- Add `DriftSyncOutbox` with durable queue persistence, retry metadata, dead letters, and restart recovery.
- Wire outbox table creation into schema creation and schema upgrade paths.

## 0.1.0

- Add `DriftSyncStorage` with optimistic entity persistence and tombstones.
- Add acknowledgement and LWW-frontier persistence with causally safe pruning.
- Add generated Drift-table support and additive schema-manifest validation.
