import 'dart:async';

import 'package:sync_engine/sync_engine.dart';

import 'task.dart';

/// Deliberately small local store for the demo. Production apps can replace it
/// with `DriftSyncStorage` without changing the UI or transport contract.
class TaskStorage implements SyncStorage {
  final Map<String, Task> _tasks = <String, Task>{};
  final Map<String, VectorClock> _clocks = <String, VectorClock>{};
  final Map<String, String> _nodeIds = <String, String>{};
  final Map<String, Map<String, FieldLwwMetadata>> _fieldMetadata =
      <String, Map<String, FieldLwwMetadata>>{};
  final Set<String> _tombstones = <String>{};
  final _controller = StreamController<List<Task>>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> save<T>(
    String id,
    T entity,
    VectorClock clock,
    String nodeId,
  ) async {
    _tasks[id] = entity as Task;
    _clocks[id] = clock;
    _nodeIds[id] = nodeId;
    _fieldMetadata[id] = const {};
    _tombstones.remove(id);
    _emit();
  }

  @override
  Future<T?> load<T>(String id) async => _tasks[id] as T?;

  @override
  Future<List<T>> loadAll<T>() async => _tasks.values.cast<T>().toList();

  @override
  Future<void> delete<T>(String id, VectorClock clock, String nodeId) async {
    _tasks.remove(id);
    _clocks[id] = clock;
    _nodeIds[id] = nodeId;
    _tombstones.add(id);
    _emit();
  }

  @override
  Future<SyncStoredEntity<Object?>?> loadStored(Type type, String id) async {
    if (type != Task || !_clocks.containsKey(id)) return null;
    final deleted = _tombstones.contains(id);
    return SyncStoredEntity(
      value: deleted ? null : _tasks[id],
      clock: _clocks[id]!,
      nodeId: _nodeIds[id] ?? '',
      deleted: deleted,
      fieldMetadata: _fieldMetadata[id] ?? const {},
    );
  }

  @override
  Future<void> saveStored(
    Type type,
    String id,
    Object entity,
    VectorClock clock,
    String nodeId,
    Map<String, FieldLwwMetadata> fieldMetadata,
  ) async {
    if (type != Task || entity is! Task) {
      throw ArgumentError.value(entity, 'entity', 'Expected a Task entity.');
    }
    _tasks[id] = entity;
    _clocks[id] = clock;
    _nodeIds[id] = nodeId;
    _fieldMetadata[id] = fieldMetadata;
    _tombstones.remove(id);
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
    if (type != Task) {
      throw ArgumentError.value(type, 'type', 'Expected Task.');
    }
    _tasks.remove(id);
    _clocks[id] = clock;
    _nodeIds[id] = nodeId;
    _fieldMetadata[id] = fieldMetadata;
    _tombstones.add(id);
    _emit();
  }

  @override
  Stream<List<T>> watch<T>() async* {
    yield _tasks.values.cast<T>().toList();
    yield* _controller.stream.map((tasks) => tasks.cast<T>());
  }

  void _emit() => _controller.add(_tasks.values.toList());

  Future<void> dispose() => _controller.close();
}
