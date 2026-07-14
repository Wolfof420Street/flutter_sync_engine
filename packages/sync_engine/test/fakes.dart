import 'dart:async';

import 'package:sync_engine/sync_engine.dart';

class FakeSyncStorage implements SyncStorage {
  final Map<Type, Map<String, Object>> _values = {};
  final Map<Type, StreamController<List<Object>>> _controllers = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<void> save<T>(String id, T entity, VectorClock clock) async {
    (_values[T] ??= {})[id] = entity as Object;
    _emit<T>();
  }

  @override
  Future<T?> load<T>(String id) async => _values[T]?[id] as T?;

  @override
  Future<List<T>> loadAll<T>() async =>
      (_values[T]?.values.cast<T>().toList() ?? <T>[]);

  @override
  Future<void> delete<T>(String id) async {
    _values[T]?.remove(id);
    _emit<T>();
  }

  @override
  Stream<List<T>> watch<T>() {
    final controller = _controllers.putIfAbsent(
      T,
      () => StreamController<List<Object>>.broadcast(),
    );
    return controller.stream.map((values) => values.cast<T>());
  }

  void _emit<T>() {
    _controllers[T]?.add(_current<T>());
  }

  List<Object> _current<T>() => _values[T]?.values.toList() ?? const [];
}

class FakeSyncTransport implements SyncTransport {
  FakeSyncTransport({List<Object> responses = const []})
      : _responses = List<Object>.from(responses);

  final List<Object> _responses;
  final List<List<SyncOperation>> pushes = [];
  final notificationsController =
      StreamController<SyncNotification>.broadcast();
  int pulls = 0;

  @override
  Stream<SyncNotification> get notifications => notificationsController.stream;

  @override
  Future<SyncBatch> pull({required String lastSyncToken}) async {
    pulls++;
    return const SyncBatch(nextSyncToken: 'next');
  }

  @override
  Future<SyncResult> push(List<SyncOperation> operations) async {
    pushes.add(operations);
    if (_responses.isEmpty) return SyncResult.accepted(operations);
    final response = _responses.removeAt(0);
    if (response is Exception) throw response;
    return response as SyncResult;
  }
}

class Task {
  const Task(this.id, this.title);

  final String id;
  final String title;

  @override
  bool operator ==(Object other) =>
      other is Task && other.id == id && other.title == title;

  @override
  int get hashCode => Object.hash(id, title);
}

class TaskAdapter implements SyncAdapter<Task> {
  @override
  String get entityType => 'task';

  @override
  String idOf(Task entity) => entity.id;
}
