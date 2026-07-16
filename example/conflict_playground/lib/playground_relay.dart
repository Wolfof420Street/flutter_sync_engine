import 'dart:async';
import 'dart:collection';

import 'package:sync_engine/sync_engine.dart';

/// Deterministic in-memory network that only relays operations between devices.
/// Merge decisions remain inside each real [SyncEngine].
class PlaygroundRelay {
  bool online = true;
  final List<PlaygroundTransport> _peers = [];

  PlaygroundTransport connect() {
    final peer = PlaygroundTransport._(this);
    _peers.add(peer);
    return peer;
  }

  void relay(PlaygroundTransport sender, List<SyncOperation> operations) {
    if (!online) throw StateError('Both devices are offline.');
    for (final peer in _peers.where((peer) => peer != sender)) {
      peer._inbox.addAll(operations);
    }
  }
}

class PlaygroundTransport implements SyncTransport {
  PlaygroundTransport._(this._relay);

  final PlaygroundRelay _relay;
  final Queue<SyncOperation> _inbox = Queue<SyncOperation>();
  final _notifications = StreamController<SyncNotification>.broadcast();

  @override
  Stream<SyncNotification> get notifications => _notifications.stream;

  @override
  Future<SyncBatch> pull({required String lastSyncToken}) async {
    if (!_relay.online) throw StateError('Both devices are offline.');
    final operations = _inbox.toList();
    _inbox.clear();
    return SyncBatch(operations: operations, nextSyncToken: 'playground');
  }

  @override
  Future<SyncResult> push(List<SyncOperation> operations) async {
    _relay.relay(this, operations);
    return SyncResult.accepted(operations);
  }

  Future<void> dispose() => _notifications.close();
}
