# Offline task manager

Flutter demo for `sync_engine`. It uses generated `@Syncable` task adapters,
optimistic local writes, a real HTTP `TaskTransport`, and a synthetic Shelf
server. The server stores only synthetic in-memory data for one process
lifetime; do not send real user data to it.

## Prerequisites

- Flutter SDK
- Dart SDK (bundled with Flutter is fine)

## Run the demo

In one terminal, start the local Shelf server:

```sh
dart run bin/mock_server.dart
```

In another terminal, run the Flutter app:

```sh
flutter pub get
flutter run
```

The app targets `http://127.0.0.1:8080`. On an emulator or physical device,
adjust the host in `lib/main.dart` to reach the host machine.

## Demo flow

1. Toggle **Offline simulation** on. This is a client-side transport switch;
   it intentionally fails before HTTP and lets `SyncOutbox` keep operations.
2. Add or edit a task. It appears immediately and the pending count increases.
3. Toggle online, then tap sync. The pending count drains through the real
   outbox/transport path.
4. The server injects occasional synthetic rejections. A rejected optimistic
   write is rolled back and appears in the warning-icon conflict log.

Dead letters are shown in the status row after the outbox exhausts its normal
retry policy. This demo keeps the production defaults (2-second exponential
backoff, 60-second cap, eight attempts), so a dead-letter demonstration takes
time; widget tests use deterministic transports for fast coverage.

## Tests

```sh
flutter test
```

The localhost Shelf integration test is opt-in because some sandboxes prohibit
socket binding:

```sh
RUN_HTTP_INTEGRATION=true flutter test test/http_transport_test.dart
```

GitHub Actions enables that flag. The test starts and terminates its own Shelf
process.
