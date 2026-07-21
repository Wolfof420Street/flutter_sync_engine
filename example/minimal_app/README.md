# Minimal SyncForge app

This is the shortest public-consumer path. It imports only
`package:sync_engine/sync_engine.dart`.

```dart
@Syncable()
class Todo {
  const Todo({required this.id, required this.title});

  @Id()
  final String id;

  @ConflictStrategy(ConflictType.lastWriteWins)
  final String title;
}
```

```sh
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

The generated `TodoSyncAdapter` is passed to `SyncEngine` alongside your
`SyncStorage` and `SyncTransport` implementations. Replace the deliberately
tiny demo adapters in `main.dart` with Drift and your backend transport.
