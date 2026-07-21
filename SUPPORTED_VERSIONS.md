# Supported Versions

SyncForge follows semantic versioning.

Current support targets:

- `sync_engine`: Dart `^3.5.0`
- `sync_engine_drift`: Flutter stable toolchains compatible with the workspace
- `sync_engine_generator`: Dart `^3.7.0`

Support policy:

- The repository is validated on the current stable Flutter toolchain used in
  CI.
- The public API is intended to remain source-compatible within a major
  version.
- Breaking changes require an explicit migration note and changelog entry.

For example applications, the supported path is the checked-in source in this
repository. Generated code and local overrides are not a published support
surface.
