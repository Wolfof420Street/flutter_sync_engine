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
      required this.id,
      required this.title,
      required this.tags});

  final VectorClock vectorClock;
  final String nodeId;
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

  Task fromJson(Map<String, dynamic> json) => Task(
      id: json['id'] as String,
      title: json['title'] as String,
      tags: (json['tags'] as List).cast<String>().toSet());
}

class TaskSyncAdapter implements SyncAdapter<Task> {
  const TaskSyncAdapter();

  @override
  String get entityType => 'task';

  @override
  String idOf(Task entity) => entity.id;

  TaskSyncModel toModel(Task entity, VectorClock vectorClock, String nodeId) =>
      TaskSyncModel(
          vectorClock: vectorClock,
          nodeId: nodeId,
          id: entity.id,
          title: entity.title,
          tags: entity.tags);

  TaskSyncModel mergeModels(TaskSyncModel local, TaskSyncModel remote) =>
      TaskSyncModel(
        id: LWWRegister(
                value: local.id,
                timestamp: local.vectorClock,
                nodeId: local.nodeId)
            .merge(LWWRegister(
                value: remote.id,
                timestamp: remote.vectorClock,
                nodeId: remote.nodeId))
            .value,
        title: LWWRegister(
                value: local.title,
                timestamp: local.vectorClock,
                nodeId: local.nodeId)
            .merge(LWWRegister(
                value: remote.title,
                timestamp: remote.vectorClock,
                nodeId: remote.nodeId))
            .value,
        tags: GSet(local.tags).merge(GSet(remote.tags)).value,
        vectorClock: local.vectorClock.merge(remote.vectorClock),
        nodeId: local.nodeId.compareTo(remote.nodeId) < 0
            ? remote.nodeId
            : local.nodeId,
      );
}

void registerTaskSyncAdapter(SyncEngine engine) {
  engine.register<Task>(const TaskSyncAdapter());
}
