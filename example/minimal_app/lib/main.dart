import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sync_engine/sync_engine.dart';

import 'todo.dart';

void main() {
  final sync = SyncEngine(
    storage: _TodoStorage(),
    transport: _DemoTransport(),
    nodeId: 'my-device',
    adapters: {Todo: const TodoSyncAdapter()},
  );
  runApp(MinimalApp(sync: sync));
}

class MinimalApp extends StatelessWidget {
  const MinimalApp({super.key, required this.sync});
  final SyncEngine sync;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('SyncForge in five minutes')),
          body: const Center(
            child: Text('Add @Syncable. Generate an adapter. Supply storage + transport.'),
          ),
        ),
      );
}

class _TodoStorage implements SyncStorage {
  @override
  Future<void> initialize() async {}
  @override
  Future<void> delete<T>(String id, VectorClock clock, String nodeId) async {}
  @override
  Future<void> deleteStored(Type type, String id, VectorClock clock, String nodeId,
      [Map<String, FieldLwwMetadata> fieldMetadata = const {}]) async {}
  @override
  Future<T?> load<T>(String id) async => null;
  @override
  Future<List<T>> loadAll<T>() async => const [];
  @override
  Future<SyncStoredEntity<Object?>?> loadStored(Type type, String id) async => null;
  @override
  Future<void> save<T>(String id, T entity, VectorClock clock, String nodeId) async {}
  @override
  Future<void> saveStored(Type type, String id, Object entity, VectorClock clock,
      String nodeId, Map<String, FieldLwwMetadata> fieldMetadata) async {}
  @override
  Stream<List<T>> watch<T>() => const Stream.empty();
}

class _DemoTransport implements SyncTransport {
  @override
  Stream<SyncNotification> get notifications => const Stream.empty();
  @override
  Future<SyncBatch> pull({required String lastSyncToken}) async => const SyncBatch();
  @override
  Future<SyncResult> push(List<SyncOperation> operations) async =>
      SyncResult.accepted(operations);
}
