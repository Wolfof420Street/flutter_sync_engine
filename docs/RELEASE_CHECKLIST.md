# Release checklist

Before tagging a release, run:

```bash
melos bootstrap
melos run generate
melos run analyze
melos run test
```

Review generated files after `melos run generate`; generated adapters and Drift
schemas are checked in. Run `dart format --set-exit-if-changed packages example`.

For each publishable package, verify its README, CHANGELOG, LICENSE, version,
and repository metadata. Then run a dry run only:

```bash
(cd packages/sync_engine && dart pub publish --dry-run)
(cd packages/sync_engine_generator && dart pub publish --dry-run)
(cd packages/sync_engine_drift && flutter pub publish --dry-run)
```

Never publish from a dry run. Confirm the release version and changelog entries
before a separate, deliberate publish action.

## Migration review

`sync_engine_drift` schema version 2 is destructive for pre-v2 local databases
because they lack writer and per-field metadata. Consumers must reset/recreate
those local databases. Field additions remain manifest-validated; type changes,
renames, and removals require an explicit application migration.

## Consumer verification

Run both consumer examples. `task_manager` includes the live HTTP test in CI;
locally enable it with `RUN_HTTP_INTEGRATION=true`. `notes_app` is the public
API integration proof and must generate, analyze, and test cleanly.
