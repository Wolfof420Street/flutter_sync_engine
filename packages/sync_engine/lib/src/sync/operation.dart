import '../vector_clock.dart';

/// An immutable local change awaiting delivery to a synchronization transport.
sealed class SyncOperation {
  const SyncOperation({
    required this.entityType,
    required this.entityId,
    required this.vectorClock,
    this.entity,
  });

  final String entityType;
  final String entityId;
  final VectorClock vectorClock;

  /// The in-memory entity payload. Phase 3 serializers will produce wire JSON.
  final Object? entity;

  SyncOperation withVectorClock(VectorClock clock);
}

class InsertOperation extends SyncOperation {
  const InsertOperation({
    required super.entityType,
    required super.entityId,
    required super.vectorClock,
    required super.entity,
  });

  @override
  InsertOperation withVectorClock(VectorClock clock) => InsertOperation(
        entityType: entityType,
        entityId: entityId,
        vectorClock: clock,
        entity: entity,
      );
}

class UpdateOperation extends SyncOperation {
  const UpdateOperation({
    required super.entityType,
    required super.entityId,
    required super.vectorClock,
    required super.entity,
  });

  @override
  UpdateOperation withVectorClock(VectorClock clock) => UpdateOperation(
        entityType: entityType,
        entityId: entityId,
        vectorClock: clock,
        entity: entity,
      );
}

/// A tombstone operation. Its [entity] is always null.
class DeleteOperation extends SyncOperation {
  const DeleteOperation({
    required super.entityType,
    required super.entityId,
    required super.vectorClock,
  }) : super(entity: null);

  @override
  DeleteOperation withVectorClock(VectorClock clock) => DeleteOperation(
        entityType: entityType,
        entityId: entityId,
        vectorClock: clock,
      );
}
