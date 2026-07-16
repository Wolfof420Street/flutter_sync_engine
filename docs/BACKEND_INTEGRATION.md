# Backend integration proof

SyncForge intentionally does not ship a Supabase adapter in the Build Week MVP.
Supabase would require a project URL, credentials, database schema, RLS policy
and realtime channel contract; a partial adapter would look production-ready
without being safely runnable.

Instead, [`example/task_manager`](../example/task_manager) contains the
production-style REST proof: `TaskTransport` implements the public
`SyncTransport` interface, serializes requests over real localhost Shelf HTTP,
and is exercised by an opt-in live HTTP test in CI. The same boundary is where a
Supabase, GraphQL or Firebase adapter belongs—without changing the pure-Dart
engine or generated model adapters.
