import 'dart:async';

import 'package:sync_engine/sync_engine.dart';

import 'task.dart';

/// Deliberately small local store for the demo. Production apps can replace it
/// with `DriftSyncStorage` without changing the UI or transport contract.
class TaskStorage implements SyncStorage {
  final Map<String, Task> _tasks = <String, Task>{};
  final _controller = StreamController<List<Task>>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> save<T>(String id, T entity, VectorClock clock) async {
    _tasks[id] = entity as Task;
    _emit();
  }

  @override
  Future<T?> load<T>(String id) async => _tasks[id] as T?;

  @override
  Future<List<T>> loadAll<T>() async => _tasks.values.cast<T>().toList();

  @override
  Future<void> delete<T>(String id) async {
    _tasks.remove(id);
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
