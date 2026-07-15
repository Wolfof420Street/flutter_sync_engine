import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sync_engine/sync_engine.dart';

import 'task.dart';

/// HTTP transport for the separate Shelf mock-server process.
class TaskTransport implements SyncTransport {
  TaskTransport(this.baseUri);

  final Uri baseUri;
  bool online = true;
  final _notifications = StreamController<SyncNotification>.broadcast();

  @override
  Stream<SyncNotification> get notifications => _notifications.stream;

  @override
  Future<SyncBatch> pull({required String lastSyncToken}) async {
    _requireOnline();
    final response = await http.get(
      baseUri.resolve('/sync?token=$lastSyncToken'),
    );
    if (response.statusCode != 200) {
      throw StateError('Pull failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return SyncBatch(nextSyncToken: json['token'] as String? ?? '');
  }

  @override
  Future<SyncResult> push(List<SyncOperation> operations) async {
    _requireOnline();
    final response = await http.post(
      baseUri.resolve('/sync'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(<String, Object?>{
        'operations': operations.map(_operationJson).toList(),
      }),
    );
    if (response.statusCode != 200) {
      throw StateError('Push failed: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return SyncResult(
      results: [
        for (var index = 0; index < operations.length; index++)
          SyncOperationResult(
            operation: operations[index],
            disposition: results[index]['disposition'] == 'rejected'
                ? SyncDisposition.rejected
                : SyncDisposition.accepted,
            reason: results[index]['reason'] as String?,
          ),
      ],
    );
  }

  Map<String, Object?> _operationJson(SyncOperation operation) {
    final entity = operation.entity;
    return <String, Object?>{
      'kind': operation is InsertOperation
          ? 'insert'
          : operation is UpdateOperation
          ? 'update'
          : 'delete',
      'entityType': operation.entityType,
      'entityId': operation.entityId,
      'clock': operation.vectorClock.toJson(),
      if (entity is Task) 'entity': const TaskSerializer().toJson(entity),
    };
  }

  void _requireOnline() {
    if (!online) throw StateError('Offline simulation is enabled');
  }

  Future<void> dispose() => _notifications.close();
}
