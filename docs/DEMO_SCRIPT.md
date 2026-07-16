# SyncForge demo script (2–3 minutes)

## 0:00–0:20 — The problem

"Flutter apps often need to work underground, on unstable networks, or across
multiple devices. Retrying a request is easy; safely reconciling two offline
edits is not. SyncForge gives Flutter developers a reusable offline-sync
engine instead of making every app rebuild distributed-systems logic."

## 0:20–0:45 — The developer experience

Show `example/minimal_app/lib/todo.dart`.

"The app author adds `@Syncable`, marks an ID, and chooses a conflict strategy.
`build_runner` emits the serializer and adapter. Then the app supplies its own
storage and transport to `SyncEngine`. The CRDT core remains pure Dart and the
backend stays replaceable."

## 0:45–1:35 — The conflict playground

Run `example/conflict_playground`.

1. Point out Device A and Device B are offline with the same starting task.
2. Click **Make offline edits**. Device A changes title to `Buy milk` and adds
   `Oat milk is fine`; Device B changes title to `Buy eggs`.
3. Click **Sync devices**.
4. Point out the merged result: `Buy eggs` wins the same-field deterministic
   tie-break, while Device A's independent detail survives.
5. Point at **Conflict history**: this comes from the real
   `SyncEngine.conflicts` stream, not a fake UI rule.

## 1:35–2:05 — Production-shaped proof

Show `example/task_manager` and its offline toggle. Explain that it uses the
same public transport abstraction over a Shelf HTTP boundary, optimistic local
writes, rollback, retry/dead-letter handling, and visible conflict logging.

## 2:05–2:30 — Why trust it / Codex story

"Codex accelerated CRDT scaffolding, generated test fixtures, adapters, CI,
and documentation. Human decisions kept the engine pure Dart, made LWW
resolution field-level rather than entity-wide, and required evidence through
1,000-iteration property tests, convergence tests, migration fixtures, and an
external consumer app."

## Closing

"SyncForge turns a difficult offline-first systems problem into Flutter code
that starts with annotations, while keeping storage and backend choices open."
