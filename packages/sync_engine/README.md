# sync_engine

[![pub.dev](https://img.shields.io/pub/v/sync_engine.svg)](https://pub.dev/packages/sync_engine)

Pure-Dart, immutable CRDT primitives for `flutter_sync_engine`. It can be
tested with `dart test` and deliberately has no Flutter dependency.

## Getting started

Create a Flutter application and add the core package, generator, and build
runner:

```sh
flutter create my_app
cd my_app
flutter pub add sync_engine
flutter pub add --dev build_runner sync_engine_generator
```

Define a model in `lib/todo.dart`. The `part` directive is required so the
generated adapter is included in the library:

```dart
import 'package:sync_engine/sync_engine.dart';

part 'todo.sync.dart';

@Syncable()
class Todo {
	const Todo({required this.id, required this.title});

	@Id()
	final String id;

	@ConflictStrategy(ConflictType.lastWriteWins)
	final String title;
}
```

Create `build.yaml` at the application root:

```yaml
targets:
	$default:
		builders:
			sync_engine_generator|syncable:
				generate_for:
					- lib/**.dart
```

Generate the adapter:

```sh
dart run build_runner build --delete-conflicting-outputs
```

The generated `TodoSyncAdapter` is then registered with `SyncEngine`:

```dart
final sync = SyncEngine(
	storage: storage,
	transport: transport,
	nodeId: 'device-a',
	adapters: {Todo: const TodoSyncAdapter()},
);
```

`storage` must implement `SyncStorage`, and `transport` must implement
`SyncTransport`. For durable Flutter persistence, use `DriftSyncStorage` from
[`sync_engine_drift`](https://pub.dev/packages/sync_engine_drift). Its README
contains a complete database and storage setup.

## LWW conflict resolution

`LWWRegister` uses vector clocks for causal order. If two writes are
concurrent, it selects the value from the lexicographically greater node ID.
That rule is deterministic but arbitrary; applications needing domain-specific
resolution should provide it above this primitive.

`SyncEngine` serializes sync cycles, validates transport acknowledgements, and
keeps the outbox cursor from advancing when a push fails. Durable persistence
is provided by `sync_engine_drift`; the core package ships the outbox contract
and in-memory implementation.
