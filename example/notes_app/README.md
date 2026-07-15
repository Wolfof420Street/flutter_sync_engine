# Offline notes consumer example

This is a clean Flutter application that consumes only the public
`sync_engine` API. It is intentionally outside `packages/` to exercise the
same integration path used by an application developer.

## Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

The checked-in `dependency_overrides` entry points `sync_engine` to this
repository during development. Remove that override and use a hosted version
when consuming a published package.

## Walkthrough

1. Enable **Offline mode**.
2. Create or edit a note. The pending-operation indicator increases and the
   note is saved to SharedPreferences immediately.
3. Restart the app: the persisted note is restored before the first frame.
4. Disable Offline mode and press the sync icon to flush queued work.
5. Press the warning icon before a write to simulate a server conflict; open
   the conflict-log icon to inspect the emitted rollback event.

`NoteStorage` and `NoteTransport` are consumer-owned examples of the public
`SyncStorage` and `SyncTransport` contracts. Replace the demo transport with a
real backend adapter in a production app.
