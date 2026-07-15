import 'dart:async';

import 'package:sync_engine/sync_engine.dart';

class FakeSyncStorage implements SyncStorage {
  final Map<Type, Map<String, Object>> _values = {};
  final Map<Type, Map<String, VectorClock>> _clocks = {};
  final Map<Type, Map<String, String>> _nodeIds = {};
  final Map<Type, Map<String, Map<String, FieldLwwMetadata>>> _fieldMetadata =
      {};
  final Map<Type, Set<String>> _deleted = {};
  final Map<Type, StreamController<List<Object>>> _controllers = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<void> save<T>(
      String id, T entity, VectorClock clock, String nodeId) async {
    (_values[T] ??= {})[id] = entity as Object;
    (_clocks[T] ??= {})[id] = clock;
    (_nodeIds[T] ??= {})[id] = nodeId;
    (_fieldMetadata[T] ??= {})[id] = const {};
    (_deleted[T] ??= {}).remove(id);
    _emit<T>();
  }

  @override
  Future<T?> load<T>(String id) async => _values[T]?[id] as T?;

  @override
  Future<List<T>> loadAll<T>() async =>
      (_values[T]?.values.cast<T>().toList() ?? <T>[]);

  @override
  Future<void> delete<T>(String id, VectorClock clock, String nodeId) async {
    _values[T]?.remove(id);
    (_deleted[T] ??= {}).add(id);
    (_clocks[T] ??= {})[id] = clock;
    (_nodeIds[T] ??= {})[id] = nodeId;
    _emit<T>();
  }

  @override
  Future<SyncStoredEntity<Object?>?> loadStored(Type type, String id) async {
    final clock = _clocks[type]?[id];
    if (clock == null) return null;
    final deleted = _deleted[type]?.contains(id) ?? false;
    return SyncStoredEntity(
      value: deleted ? null : _values[type]?[id],
      clock: clock,
      nodeId: _nodeIds[type]?[id] ?? '',
      deleted: deleted,
      fieldMetadata: _fieldMetadata[type]?[id] ?? const {},
    );
  }

  @override
  Future<void> saveStored(
      Type type,
      String id,
      Object entity,
      VectorClock clock,
      String nodeId,
      Map<String, FieldLwwMetadata> fieldMetadata) async {
    (_values[type] ??= {})[id] = entity;
    (_clocks[type] ??= {})[id] = clock;
    (_nodeIds[type] ??= {})[id] = nodeId;
    (_fieldMetadata[type] ??= {})[id] = fieldMetadata;
    (_deleted[type] ??= {}).remove(id);
    _emitByType(type);
  }

  @override
  Future<void> deleteStored(
      Type type, String id, VectorClock clock, String nodeId,
      [Map<String, FieldLwwMetadata> fieldMetadata = const {}]) async {
    _values[type]?.remove(id);
    (_clocks[type] ??= {})[id] = clock;
    (_nodeIds[type] ??= {})[id] = nodeId;
    (_deleted[type] ??= {}).add(id);
    _emitByType(type);
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

  void _emitByType(Type type) {
    _controllers[type]?.add(_values[type]?.values.toList() ?? const []);
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
  Type get modelType => Task;
  @override
  String get entityType => 'task';

  @override
  String idOf(Task entity) => entity.id;

  @override
  Map<String, dynamic> toJson(Task entity) =>
      {'id': entity.id, 'title': entity.title};

  @override
  Task fromJson(Map<String, dynamic> json) =>
      Task(json['id'] as String, json['title'] as String);

  @override
  SyncMergeResult<Task> merge(
      Task local,
      Task remote,
      VectorClock localClock,
      VectorClock remoteClock,
      String localNodeId,
      String remoteNodeId,
      Map<String, FieldLwwMetadata> localFieldMetadata,
      Map<String, FieldLwwMetadata> remoteFieldMetadata) {
    final title = FieldLwwMetadata.winner(
        localFieldMetadata['title']!, remoteFieldMetadata['title']!);
    return SyncMergeResult(
      title == localFieldMetadata['title']! ? local : remote,
      {'title': title},
    );
  }

  @override
  Map<String, FieldLwwMetadata> fieldMetadataForWrite(
          Task entity,
          Task? previous,
          Map<String, FieldLwwMetadata> previousMetadata,
          VectorClock clock,
          String nodeId) =>
      {
        'title': previous == null || previous.title != entity.title
            ? FieldLwwMetadata(timestamp: clock, nodeId: nodeId)
            : previousMetadata['title']!,
      };
}
