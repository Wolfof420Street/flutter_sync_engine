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
      required this.title});

  final VectorClock vectorClock;
  final String nodeId;
  final String id;
  final String title;
}

class TaskSerializer {
  const TaskSerializer();

  Map<String, dynamic> toJson(Task entity) => <String, dynamic>{
        'id': entity.id,
        'title': entity.title,
      };

  Task fromJson(Map<String, dynamic> json) => Task(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '');
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
          title: entity.title);

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
        vectorClock: local.vectorClock.merge(remote.vectorClock),
        nodeId: LWWRegister.winningNodeId(local.nodeId, remote.nodeId),
      );
}

void registerTaskSyncAdapter(SyncEngine engine) {
  engine.register<Task>(const TaskSyncAdapter());
}

@DataClassName('TaskSyncRow')
class TaskSyncTable extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()();
  TextColumn get vectorClock => text().named('vector_clock')();
  IntColumn get deleted => integer().withDefault(const Constant(0))();
  IntColumn get lastModified => integer()
      .named('last_modified')
      .withDefault(const CustomExpression<int>("strftime('%s','now')"))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
