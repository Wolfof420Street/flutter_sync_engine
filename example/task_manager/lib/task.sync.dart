// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// SyncableGenerator
// **************************************************************************

class TaskSyncModel {
  const TaskSyncModel({
    required this.vectorClock,
    required this.nodeId,
    required this.id,
    required this.title,
    required this.completed,
  });

  final VectorClock vectorClock;
  final String nodeId;
  final String id;
  final String title;
  final bool completed;
}

class TaskSerializer {
  const TaskSerializer();

  Map<String, dynamic> toJson(Task entity) => <String, dynamic>{
    'id': entity.id,
    'title': entity.title,
    'completed': entity.completed,
  };

  Task fromJson(Map<String, dynamic> json) => Task(
    id: (json['id'] as String?) ?? '',
    title: (json['title'] as String?) ?? '',
    completed: (json['completed'] as bool?) ?? false,
  );
}

class TaskSyncAdapter implements SyncAdapter<Task> {
  const TaskSyncAdapter();

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

  TaskSyncModel toModel(Task entity, VectorClock vectorClock, String nodeId) =>
      TaskSyncModel(
        vectorClock: vectorClock,
        nodeId: nodeId,
        id: entity.id,
        title: entity.title,
        completed: entity.completed,
      );

  TaskSyncModel mergeModels(TaskSyncModel local, TaskSyncModel remote) =>
      TaskSyncModel(
        id:
            LWWRegister(
                  value: local.id,
                  timestamp: local.vectorClock,
                  nodeId: local.nodeId,
                )
                .merge(
                  LWWRegister(
                    value: remote.id,
                    timestamp: remote.vectorClock,
                    nodeId: remote.nodeId,
                  ),
                )
                .value,
        title:
            LWWRegister(
                  value: local.title,
                  timestamp: local.vectorClock,
                  nodeId: local.nodeId,
                )
                .merge(
                  LWWRegister(
                    value: remote.title,
                    timestamp: remote.vectorClock,
                    nodeId: remote.nodeId,
                  ),
                )
                .value,
        completed:
            LWWRegister(
                  value: local.completed,
                  timestamp: local.vectorClock,
                  nodeId: local.nodeId,
                )
                .merge(
                  LWWRegister(
                    value: remote.completed,
                    timestamp: remote.vectorClock,
                    nodeId: remote.nodeId,
                  ),
                )
                .value,
        vectorClock: local.vectorClock.merge(remote.vectorClock),
        nodeId: LWWRegister.winningNodeId(local.nodeId, remote.nodeId),
      );
}

void registerTaskSyncAdapter(SyncEngine engine) {
  engine.register<Task>(const TaskSyncAdapter());
}
