# Drift bootstrap fixture

This is the canonical pre-additive `Task` fixture. The additive migration
fixture invokes `bin/write_legacy_payload.dart` after building this package and
consumes the JSON bytes emitted by this fixture's generated `TaskSerializer`.
Keep its `Task` shape (`id`, `title`) stable: it models data persisted before
the additive fixture introduced `completed`.

This fixture begins with no manifest file and exercises the explicit first-build
`bootstrap_schema: true` path. The bootstrap command then creates the committed
baseline before normal additive-only checks are enabled.
