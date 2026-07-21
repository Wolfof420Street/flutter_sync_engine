// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'playground_task.dart';

// **************************************************************************
// SyncableGenerator
// **************************************************************************

class PlaygroundTaskSyncModel {
  const PlaygroundTaskSyncModel({
    required this.vectorClock,
    required this.nodeId,
    required this.fieldMetadata,
    required this.id,
    required this.title,
    required this.details,
  });

  final VectorClock vectorClock;
  final String nodeId;
  final Map<String, FieldLwwMetadata> fieldMetadata;
  final String id;
  final String title;
  final String details;
}

class PlaygroundTaskSerializer {
  const PlaygroundTaskSerializer();

  Map<String, dynamic> toJson(PlaygroundTask entity) => <String, dynamic>{
    'id': entity.id,
    'title': entity.title,
    'details': entity.details,
  };

  /// Envelope form used by transports that persist field-local LWW metadata.
  Map<String, dynamic> toSyncJson(
    PlaygroundTask entity,
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

  PlaygroundTask fromJson(Map<String, dynamic> json) => PlaygroundTask(
    id: (json['id'] as String?) ?? '',
    title: (json['title'] as String?) ?? '',
    details: (json['details'] as String?) ?? '',
  );
}

class PlaygroundTaskSyncAdapter implements SyncAdapter<PlaygroundTask> {
  const PlaygroundTaskSyncAdapter();

  @override
  Type get modelType => PlaygroundTask;

  @override
  String get entityType => 'playground_task';

  @override
  String idOf(PlaygroundTask entity) => entity.id;

  @override
  Map<String, dynamic> toJson(PlaygroundTask entity) =>
      const PlaygroundTaskSerializer().toJson(entity);

  @override
  PlaygroundTask fromJson(Map<String, dynamic> json) =>
      const PlaygroundTaskSerializer().fromJson(json);

  @override
  Map<String, FieldLwwMetadata> fieldMetadataForWrite(
    PlaygroundTask entity,
    PlaygroundTask? previous,
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
    'details': previous == null || previous.details != entity.details
        ? FieldLwwMetadata(timestamp: clock, nodeId: nodeId)
        : previousMetadata['details']!,
  };

  @override
  SyncMergeResult<PlaygroundTask> merge(
    PlaygroundTask local,
    PlaygroundTask remote,
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
      PlaygroundTask(
        id: merged.id,
        title: merged.title,
        details: merged.details,
      ),
      merged.fieldMetadata,
    );
  }

  PlaygroundTaskSyncModel toModel(
    PlaygroundTask entity,
    VectorClock vectorClock,
    String nodeId,
    Map<String, FieldLwwMetadata> fieldMetadata,
  ) => PlaygroundTaskSyncModel(
    vectorClock: vectorClock,
    nodeId: nodeId,
    fieldMetadata: fieldMetadata,
    id: entity.id,
    title: entity.title,
    details: entity.details,
  );

  PlaygroundTaskSyncModel mergeModels(
    PlaygroundTaskSyncModel local,
    PlaygroundTaskSyncModel remote,
  ) {
    final idWinner = FieldLwwMetadata.winner(
      local.fieldMetadata['id']!,
      remote.fieldMetadata['id']!,
    );
    final titleWinner = FieldLwwMetadata.winner(
      local.fieldMetadata['title']!,
      remote.fieldMetadata['title']!,
    );
    final detailsWinner = FieldLwwMetadata.winner(
      local.fieldMetadata['details']!,
      remote.fieldMetadata['details']!,
    );
    return PlaygroundTaskSyncModel(
      id: idWinner == local.fieldMetadata['id'] ? local.id : remote.id,
      title: titleWinner == local.fieldMetadata['title']
          ? local.title
          : remote.title,
      details: detailsWinner == local.fieldMetadata['details']
          ? local.details
          : remote.details,
      vectorClock: local.vectorClock.merge(remote.vectorClock),
      nodeId: LWWRegister.winningNodeId(local.nodeId, remote.nodeId),
      fieldMetadata: <String, FieldLwwMetadata>{
        'id': idWinner,
        'title': titleWinner,
        'details': detailsWinner,
      },
    );
  }
}

void registerPlaygroundTaskSyncAdapter(SyncEngine engine) {
  engine.register<PlaygroundTask>(const PlaygroundTaskSyncAdapter());
}
