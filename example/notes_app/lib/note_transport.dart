import 'dart:async';

import 'package:sync_engine/sync_engine.dart';

/// A deterministic backend substitute for the external-consumer walkthrough.
/// Replace this with a REST, Supabase, or GraphQL [SyncTransport] in an app.
class NoteTransport implements SyncTransport {
  bool online = true;
  bool rejectNextWrite = false;
  final _notifications = StreamController<SyncNotification>.broadcast();

  @override
  Stream<SyncNotification> get notifications => _notifications.stream;

  @override
  Future<SyncBatch> pull({required String lastSyncToken}) async {
    _requireOnline();
    return const SyncBatch(nextSyncToken: 'local-demo');
  }

  @override
  Future<SyncResult> push(List<SyncOperation> operations) async {
    _requireOnline();
    if (rejectNextWrite) {
      rejectNextWrite = false;
      return SyncResult(
        results: [
          SyncOperationResult(
            operation: operations.single,
            disposition: SyncDisposition.rejected,
            reason: 'Demo server resolved a conflicting remote edit.',
          ),
        ],
      );
    }
    return SyncResult.accepted(operations);
  }

  void _requireOnline() {
    if (!online) throw StateError('Offline mode is enabled');
  }

  Future<void> dispose() => _notifications.close();
}
