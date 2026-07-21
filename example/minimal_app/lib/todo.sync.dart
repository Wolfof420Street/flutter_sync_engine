// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'todo.dart';

// **************************************************************************
// SyncableGenerator
// **************************************************************************

class TodoSyncModel {
  const TodoSyncModel({
    required this.vectorClock,
    required this.nodeId,
    required this.fieldMetadata,
    required this.id,
    required this.title,
  });

  final VectorClock vectorClock;
  final String nodeId;
  final Map<String, FieldLwwMetadata> fieldMetadata;
  final String id;
  final String title;
}

class TodoSerializer {
  const TodoSerializer();

  Map<String, dynamic> toJson(Todo entity) => <String, dynamic>{
    'id': entity.id,
    'title': entity.title,
  };

  /// Envelope form used by transports that persist field-local LWW metadata.
  Map<String, dynamic> toSyncJson(
    Todo entity,
    Map<String, FieldLwwMetadata> fieldMetadata,
  ) => <String, dynamic>{
    ...toJson(entity),
    '_fieldMetadata': fieldMetadata.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
  };

  Map<String, FieldLwwMetadata> fieldMetadataFromJson(
    Map<String, dynamic> json,
  ) => ((json['_fieldMetadata'] as Map<String, dynamic>?) ?? const {}).map(
    (key, value) =>
        MapEntry(key, FieldLwwMetadata.fromJson(value as Map<String, dynamic>)),
  );

  Todo fromJson(Map<String, dynamic> json) => Todo(
    id: (json['id'] as String?) ?? '',
    title: (json['title'] as String?) ?? '',
  );
}

class TodoSyncAdapter implements SyncAdapter<Todo> {
  const TodoSyncAdapter();

  @override
  Type get modelType => Todo;

  @override
  String get entityType => 'todo';

  @override
  String idOf(Todo entity) => entity.id;

  @override
  Map<String, dynamic> toJson(Todo entity) =>
      const TodoSerializer().toJson(entity);

  @override
  Todo fromJson(Map<String, dynamic> json) =>
      const TodoSerializer().fromJson(json);

  @override
  Map<String, FieldLwwMetadata> fieldMetadataForWrite(
    Todo entity,
    Todo? previous,
    Map<String, FieldLwwMetadata> previousMetadata,
    VectorClock clock,
    String nodeId,
  ) => <String, FieldLwwMetadata>{
    'id': previous == null || previous.id != entity.id
        ? FieldLwwMetadata(timestamp: clock, nodeId: nodeId)
        : previousMetadata['id']!,
    'title': previous == null || previous.title != entity.title
        ? FieldLwwMetadata(timestamp: clock, nodeId: nodeId)
        : previousMetadata['title']!,
  };

  @override
  SyncMergeResult<Todo> merge(
    Todo local,
    Todo remote,
    VectorClock localClock,
    VectorClock remoteClock,
    String localNodeId,
    String remoteNodeId,
    Map<String, FieldLwwMetadata> localFieldMetadata,
    Map<String, FieldLwwMetadata> remoteFieldMetadata,
  ) {
    final merged = mergeModels(
      toModel(local, localClock, localNodeId, localFieldMetadata),
      toModel(remote, remoteClock, remoteNodeId, remoteFieldMetadata),
    );
    return SyncMergeResult(
      Todo(id: merged.id, title: merged.title),
      merged.fieldMetadata,
    );
  }

  TodoSyncModel toModel(
    Todo entity,
    VectorClock vectorClock,
    String nodeId,
    Map<String, FieldLwwMetadata> fieldMetadata,
  ) => TodoSyncModel(
    vectorClock: vectorClock,
    nodeId: nodeId,
    fieldMetadata: fieldMetadata,
    id: entity.id,
    title: entity.title,
  );

  TodoSyncModel mergeModels(TodoSyncModel local, TodoSyncModel remote) {
    final idWinner = FieldLwwMetadata.winner(
      local.fieldMetadata['id']!,
      remote.fieldMetadata['id']!,
    );
    final titleWinner = FieldLwwMetadata.winner(
      local.fieldMetadata['title']!,
      remote.fieldMetadata['title']!,
    );
    return TodoSyncModel(
      id: idWinner == local.fieldMetadata['id'] ? local.id : remote.id,
      title: titleWinner == local.fieldMetadata['title']
          ? local.title
          : remote.title,
      vectorClock: local.vectorClock.merge(remote.vectorClock),
      nodeId: LWWRegister.winningNodeId(local.nodeId, remote.nodeId),
      fieldMetadata: <String, FieldLwwMetadata>{
        'id': idWinner,
        'title': titleWinner,
      },
    );
  }
}

void registerTodoSyncAdapter(SyncEngine engine) {
  engine.register<Todo>(const TodoSyncAdapter());
}
