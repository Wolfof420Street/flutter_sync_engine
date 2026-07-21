# SyncForge Conflict Playground

The visual Build Week demo for SyncForge. It runs **two real `SyncEngine`
instances** with generated `PlaygroundTaskSyncAdapter`s, independent local
stores, and an in-memory relay that only transports operations. It does not
contain a second CRDT implementation.

## Run

```sh
cd example/conflict_playground
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

Click **Make offline edits**: Device A writes `Buy milk` plus a detail, while
Device B writes `Buy eggs`. Click **Sync devices**. The title resolves to
`Buy eggs` because `device-b` wins the documented lexicographic LWW tie-break;
Device A's independent detail remains. The conflict history is emitted by the
real `SyncEngine.conflicts` stream.

Run the deterministic demo test with `flutter test`.
