# Supported Versions

SyncForge follows semantic versioning.

Current support targets:

- `sync_engine`: Dart `^3.5.0`
- `sync_engine_drift`: Dart `^3.5.0`, Flutter `>=3.24.0`
- `sync_engine_generator`: Dart `^3.7.0`

Support policy:

- The repository is validated on the current stable Flutter toolchain used in
  CI. The Drift adapter declares Flutter 3.24.0 as its minimum because its
  Dart SDK constraint is 3.5.0 and its current Drift/SQLite dependencies are
  not compatible with the legacy Flutter 1.17 floor.
- The public API is intended to remain source-compatible within a major
  version.
- Breaking changes require an explicit migration note and changelog entry.

For example applications, the supported path is the checked-in source in this
repository. Generated code and local overrides are not a published support
surface.
