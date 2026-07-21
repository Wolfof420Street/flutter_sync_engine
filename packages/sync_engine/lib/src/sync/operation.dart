import 'dart:convert';

import '../vector_clock.dart';
import 'adapter.dart';

/// An immutable local change awaiting delivery to a synchronization transport.
sealed class SyncOperation {
  const SyncOperation({
    required this.entityType,
    required this.entityId,
    required this.vectorClock,
    this.nodeId = '',
    this.fieldMetadata = const {},
    this.serializedEntity,
    this.entity,
  });

  final String entityType;
  final String entityId;
  final VectorClock vectorClock;
  final String nodeId;
  final Map<String, FieldLwwMetadata> fieldMetadata;
  final Map<String, dynamic>? serializedEntity;

  /// The in-memory entity payload. Phase 3 serializers will produce wire JSON.
  final Object? entity;

  SyncOperation withVectorClock(VectorClock clock);

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is SyncOperation &&
      other.entityType == entityType &&
      other.entityId == entityId &&
      other.vectorClock == vectorClock &&
      other.nodeId == nodeId &&
      _sameFieldMetadata(other.fieldMetadata) &&
      jsonEncode(other.serializedEntity) == jsonEncode(serializedEntity);

  @override
  int get hashCode => Object.hash(
        runtimeType,
        entityType,
        entityId,
        vectorClock,
        nodeId,
        Object.hashAll(
          fieldMetadata.entries.map(
            (entry) => Object.hash(entry.key, entry.value),
          ),
        ),
        jsonEncode(serializedEntity),
      );

  bool _sameFieldMetadata(Map<String, FieldLwwMetadata> other) {
    if (fieldMetadata.length != other.length) return false;
    for (final entry in fieldMetadata.entries) {
      if (other[entry.key] != entry.value) return false;
    }
    return true;
  }
}

class InsertOperation extends SyncOperation {
  const InsertOperation({
    required super.entityType,
    required super.entityId,
    required super.vectorClock,
    super.nodeId,
    super.fieldMetadata,
    super.serializedEntity,
    required super.entity,
  });

  @override
  InsertOperation withVectorClock(VectorClock clock) => InsertOperation(
        entityType: entityType,
        entityId: entityId,
        vectorClock: clock,
        nodeId: nodeId,
        fieldMetadata: fieldMetadata,
        serializedEntity: serializedEntity,
        entity: entity,
      );
}

class UpdateOperation extends SyncOperation {
  const UpdateOperation({
    required super.entityType,
    required super.entityId,
    required super.vectorClock,
    super.nodeId,
    super.fieldMetadata,
    super.serializedEntity,
    required super.entity,
  });

  @override
  UpdateOperation withVectorClock(VectorClock clock) => UpdateOperation(
        entityType: entityType,
        entityId: entityId,
        vectorClock: clock,
        nodeId: nodeId,
        fieldMetadata: fieldMetadata,
        serializedEntity: serializedEntity,
        entity: entity,
      );
}

/// A tombstone operation. Its [entity] is always null.
class DeleteOperation extends SyncOperation {
  const DeleteOperation({
    required super.entityType,
    required super.entityId,
    required super.vectorClock,
    super.nodeId,
    super.fieldMetadata,
    super.serializedEntity,
  }) : super(entity: null);

  @override
  DeleteOperation withVectorClock(VectorClock clock) => DeleteOperation(
        entityType: entityType,
        entityId: entityId,
        vectorClock: clock,
        nodeId: nodeId,
        fieldMetadata: fieldMetadata,
        serializedEntity: serializedEntity,
      );
}
