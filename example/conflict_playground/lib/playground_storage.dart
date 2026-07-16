import 'dart:async';

import 'package:sync_engine/sync_engine.dart';

import 'playground_task.dart';

/// Small in-memory store used only by the visual playground.
class PlaygroundStorage implements SyncStorage {
  final Map<String, SyncStoredEntity<Object?>> _records = {};
  final _changes = StreamController<List<PlaygroundTask>>.broadcast();

  SyncStoredEntity<Object?>? record(String id) => _records[id];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> save<T>(
    String id,
    T entity,
    VectorClock clock,
    String nodeId,
  ) => saveStored(T, id, entity as Object, clock, nodeId, const {});

  @override
  Future<T?> load<T>(String id) async => _records[id]?.value as T?;

  @override
  Future<List<T>> loadAll<T>() async => _records.values
      .where((record) => !record.deleted)
      .map((record) => record.value)
      .whereType<T>()
      .toList();

  @override
  Future<void> delete<T>(String id, VectorClock clock, String nodeId) =>
      deleteStored(T, id, clock, nodeId);

  @override
  Future<SyncStoredEntity<Object?>?> loadStored(Type type, String id) async =>
      type == PlaygroundTask ? _records[id] : null;

  @override
  Future<void> saveStored(
    Type type,
    String id,
    Object entity,
    VectorClock clock,
    String nodeId,
    Map<String, FieldLwwMetadata> fieldMetadata,
  ) async {
    _records[id] = SyncStoredEntity(
      value: entity,
      clock: clock,
      nodeId: nodeId,
      deleted: false,
      fieldMetadata: fieldMetadata,
    );
    _emit();
  }

  @override
  Future<void> deleteStored(
    Type type,
    String id,
    VectorClock clock,
    String nodeId, [
    Map<String, FieldLwwMetadata> fieldMetadata = const {},
  ]) async {
    _records[id] = SyncStoredEntity(
      value: null,
      clock: clock,
      nodeId: nodeId,
      deleted: true,
      fieldMetadata: fieldMetadata,
    );
    _emit();
  }

  @override
  Stream<List<T>> watch<T>() async* {
    yield await loadAll<T>();
    yield* _changes.stream.map((tasks) => tasks.cast<T>());
  }

  void _emit() => _changes.add(_records.values
      .where((record) => !record.deleted)
      .map((record) => record.value)
      .whereType<PlaygroundTask>()
      .toList());

  Future<void> dispose() => _changes.close();
}
