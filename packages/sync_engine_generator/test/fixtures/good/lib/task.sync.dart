// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// SyncableGenerator
// **************************************************************************

class TaskSyncModel {
  const TaskSyncModel(
      {required this.vectorClock,
      required this.nodeId,
      required this.fieldMetadata,
      required this.id,
      required this.title,
      required this.tags});

  final VectorClock vectorClock;
  final String nodeId;
  final Map<String, FieldLwwMetadata> fieldMetadata;
  final String id;
  final String title;
  final Set<String> tags;
}

class TaskSerializer {
  const TaskSerializer();

  Map<String, dynamic> toJson(Task entity) => <String, dynamic>{
        'id': entity.id,
        'title': entity.title,
        'tags': entity.tags.toList(),
      };

  /// Envelope form used by transports that persist field-local LWW metadata.
  Map<String, dynamic> toSyncJson(
          Task entity, Map<String, FieldLwwMetadata> fieldMetadata) =>
      <String, dynamic>{
        ...toJson(entity),
        '_fieldMetadata':
            fieldMetadata.map((key, value) => MapEntry(key, value.toJson())),
      };

  Map<String, FieldLwwMetadata> fieldMetadataFromJson(
          Map<String, dynamic> json) =>
      ((json['_fieldMetadata'] as Map<String, dynamic>?) ?? const {}).map(
          (key, value) => MapEntry(
              key, FieldLwwMetadata.fromJson(value as Map<String, dynamic>)));

  Task fromJson(Map<String, dynamic> json) => Task(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      tags: ((json['tags'] as List?) ?? const <dynamic>[])
          .cast<String>()
          .toSet());
}

class TaskSyncAdapter implements SyncAdapter<Task> {
  const TaskSyncAdapter();

  @override
  Type get modelType => Task;

  @override
  String get entityType => 'task';

  @override
  String idOf(Task entity) => entity.id;

  @override
  Map<String, dynamic> toJson(Task entity) =>
      const TaskSerializer().toJson(entity);

  @override
  Task fromJson(Map<String, dynamic> json) =>
      const TaskSerializer().fromJson(json);

  @override
  Map<String, FieldLwwMetadata> fieldMetadataForWrite(
          Task entity,
          Task? previous,
          Map<String, FieldLwwMetadata> previousMetadata,
          VectorClock clock,
          String nodeId) =>
      <String, FieldLwwMetadata>{
        'id': previous == null || previous.id != entity.id
            ? FieldLwwMetadata(timestamp: clock, nodeId: nodeId)
            : previousMetadata['id']!,
        'title': previous == null || previous.title != entity.title
            ? FieldLwwMetadata(timestamp: clock, nodeId: nodeId)
            : previousMetadata['title']!
      };

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
    final merged = mergeModels(
      toModel(local, localClock, localNodeId, localFieldMetadata),
      toModel(remote, remoteClock, remoteNodeId, remoteFieldMetadata),
    );
    return SyncMergeResult(
        Task(id: merged.id, title: merged.title, tags: merged.tags),
        merged.fieldMetadata);
  }

  TaskSyncModel toModel(Task entity, VectorClock vectorClock, String nodeId,
          Map<String, FieldLwwMetadata> fieldMetadata) =>
      TaskSyncModel(
          vectorClock: vectorClock,
          nodeId: nodeId,
          fieldMetadata: fieldMetadata,
          id: entity.id,
          title: entity.title,
          tags: entity.tags);

  TaskSyncModel mergeModels(TaskSyncModel local, TaskSyncModel remote) {
    final idWinner = FieldLwwMetadata.winner(
        local.fieldMetadata['id']!, remote.fieldMetadata['id']!);
    final titleWinner = FieldLwwMetadata.winner(
        local.fieldMetadata['title']!, remote.fieldMetadata['title']!);
    return TaskSyncModel(
      id: idWinner == local.fieldMetadata['id'] ? local.id : remote.id,
      title: titleWinner == local.fieldMetadata['title']
          ? local.title
          : remote.title,
      tags: GSet(local.tags).merge(GSet(remote.tags)).value,
      vectorClock: local.vectorClock.merge(remote.vectorClock),
      nodeId: LWWRegister.winningNodeId(local.nodeId, remote.nodeId),
      fieldMetadata: <String, FieldLwwMetadata>{
        'id': idWinner,
        'title': titleWinner
      },
    );
  }
}

void registerTaskSyncAdapter(SyncEngine engine) {
  engine.register<Task>(const TaskSyncAdapter());
}
