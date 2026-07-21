// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'note.dart';

// **************************************************************************
// SyncableGenerator
// **************************************************************************

class NoteSyncModel {
  const NoteSyncModel({
    required this.vectorClock,
    required this.nodeId,
    required this.fieldMetadata,
    required this.id,
    required this.title,
    required this.body,
  });

  final VectorClock vectorClock;
  final String nodeId;
  final Map<String, FieldLwwMetadata> fieldMetadata;
  final String id;
  final String title;
  final String body;
}

class NoteSerializer {
  const NoteSerializer();

  Map<String, dynamic> toJson(Note entity) => <String, dynamic>{
    'id': entity.id,
    'title': entity.title,
    'body': entity.body,
  };

  /// Envelope form used by transports that persist field-local LWW metadata.
  Map<String, dynamic> toSyncJson(
    Note entity,
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

  Note fromJson(Map<String, dynamic> json) => Note(
    id: (json['id'] as String?) ?? '',
    title: (json['title'] as String?) ?? '',
    body: (json['body'] as String?) ?? '',
  );
}

class NoteSyncAdapter implements SyncAdapter<Note> {
  const NoteSyncAdapter();

  @override
  Type get modelType => Note;

  @override
  String get entityType => 'note';

  @override
  String idOf(Note entity) => entity.id;

  @override
  Map<String, dynamic> toJson(Note entity) =>
      const NoteSerializer().toJson(entity);

  @override
  Note fromJson(Map<String, dynamic> json) =>
      const NoteSerializer().fromJson(json);

  @override
  Map<String, FieldLwwMetadata> fieldMetadataForWrite(
    Note entity,
    Note? previous,
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
    'body': previous == null || previous.body != entity.body
        ? FieldLwwMetadata(timestamp: clock, nodeId: nodeId)
        : previousMetadata['body']!,
  };

  @override
  SyncMergeResult<Note> merge(
    Note local,
    Note remote,
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
      Note(id: merged.id, title: merged.title, body: merged.body),
      merged.fieldMetadata,
    );
  }

  NoteSyncModel toModel(
    Note entity,
    VectorClock vectorClock,
    String nodeId,
    Map<String, FieldLwwMetadata> fieldMetadata,
  ) => NoteSyncModel(
    vectorClock: vectorClock,
    nodeId: nodeId,
    fieldMetadata: fieldMetadata,
    id: entity.id,
    title: entity.title,
    body: entity.body,
  );

  NoteSyncModel mergeModels(NoteSyncModel local, NoteSyncModel remote) {
    final idWinner = FieldLwwMetadata.winner(
      local.fieldMetadata['id']!,
      remote.fieldMetadata['id']!,
    );
    final titleWinner = FieldLwwMetadata.winner(
      local.fieldMetadata['title']!,
      remote.fieldMetadata['title']!,
    );
    final bodyWinner = FieldLwwMetadata.winner(
      local.fieldMetadata['body']!,
      remote.fieldMetadata['body']!,
    );
    return NoteSyncModel(
      id: idWinner == local.fieldMetadata['id'] ? local.id : remote.id,
      title: titleWinner == local.fieldMetadata['title']
          ? local.title
          : remote.title,
      body: bodyWinner == local.fieldMetadata['body']
          ? local.body
          : remote.body,
      vectorClock: local.vectorClock.merge(remote.vectorClock),
      nodeId: LWWRegister.winningNodeId(local.nodeId, remote.nodeId),
      fieldMetadata: <String, FieldLwwMetadata>{
        'id': idWinner,
        'title': titleWinner,
        'body': bodyWinner,
      },
    );
  }
}

void registerNoteSyncAdapter(SyncEngine engine) {
  engine.register<Note>(const NoteSyncAdapter());
}
