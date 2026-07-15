import '../vector_clock.dart';
import '../crdt/lww_register.dart';

/// Durable timestamp and author for one last-write-wins field.
class FieldLwwMetadata {
  const FieldLwwMetadata({required this.timestamp, required this.nodeId});

  final VectorClock timestamp;
  final String nodeId;

  factory FieldLwwMetadata.fromJson(Map<String, dynamic> json) =>
      FieldLwwMetadata(
        timestamp:
            VectorClock.fromJson(json['timestamp'] as Map<String, dynamic>),
        nodeId: json['nodeId'] as String,
      );

  Map<String, dynamic> toJson() =>
      {'timestamp': timestamp.toJson(), 'nodeId': nodeId};

  static FieldLwwMetadata winner(
          FieldLwwMetadata local, FieldLwwMetadata remote) =>
      LWWRegister(
        value: local,
        timestamp: local.timestamp,
        nodeId: local.nodeId,
      )
          .merge(LWWRegister(
            value: remote,
            timestamp: remote.timestamp,
            nodeId: remote.nodeId,
          ))
          .value;

  @override
  bool operator ==(Object other) =>
      other is FieldLwwMetadata &&
      other.timestamp == timestamp &&
      other.nodeId == nodeId;

  @override
  int get hashCode => Object.hash(timestamp, nodeId);
}

/// Result of an entity merge, including independently resolved field metadata.
class SyncMergeResult<T> {
  const SyncMergeResult(this.value, this.fieldMetadata);

  final T value;
  final Map<String, FieldLwwMetadata> fieldMetadata;
}

/// Supplies the entity-specific details required by the generic sync engine.
abstract class SyncAdapter<T> {
  /// Runtime model type used for engine-to-storage dispatch.
  Type get modelType;

  /// Stable type name sent to the transport.
  String get entityType;

  /// Extracts the stable identifier from [entity].
  String idOf(T entity);

  /// Converts an entity to a transport and persistence-safe JSON map.
  Map<String, dynamic> toJson(T entity);

  /// Restores an entity from a transport and persistence-safe JSON map.
  T fromJson(Map<String, dynamic> json);

  /// Builds field-local LWW metadata for a newly authored entity value.
  Map<String, FieldLwwMetadata> fieldMetadataForWrite(
    T entity,
    T? previous,
    Map<String, FieldLwwMetadata> previousMetadata,
    VectorClock clock,
    String nodeId,
  );

  /// Merges two materialized values using entity and field-local metadata.
  SyncMergeResult<T> merge(
    T local,
    T remote,
    VectorClock localClock,
    VectorClock remoteClock,
    String localNodeId,
    String remoteNodeId,
    Map<String, FieldLwwMetadata> localFieldMetadata,
    Map<String, FieldLwwMetadata> remoteFieldMetadata,
  );
}

/// Thrown when an operation is attempted for a type without an adapter.
class UnregisteredSyncTypeError extends StateError {
  UnregisteredSyncTypeError(Object type)
      : super(
            'No SyncAdapter is registered for type $type. Add @Syncable or register an adapter.');
}
