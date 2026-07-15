import '../vector_clock.dart';
import 'adapter.dart';
import 'operation.dart';

/// Persistence contract implemented by pluggable storage adapters.
abstract class SyncStorage {
  Future<void> initialize();

  /// Persists an entity with the identity that authored [clock].
  Future<void> save<T>(String id, T entity, VectorClock clock, String nodeId);
  Future<T?> load<T>(String id);
  Future<List<T>> loadAll<T>();

  /// Persists a tombstone with its causal metadata and author identity.
  Future<void> delete<T>(String id, VectorClock clock, String nodeId);
  Stream<List<T>> watch<T>();

  /// Reads an entity or tombstone with its durable causal metadata.
  Future<SyncStoredEntity<Object?>?> loadStored(Type type, String id);

  /// Untyped engine-facing persistence path, keyed by a registered model type.
  Future<void> saveStored(
      Type type,
      String id,
      Object entity,
      VectorClock clock,
      String nodeId,
      Map<String, FieldLwwMetadata> fieldMetadata);

  /// Persists a tombstone and its causal metadata.
  Future<void> deleteStored(
      Type type, String id, VectorClock clock, String nodeId,
      [Map<String, FieldLwwMetadata> fieldMetadata = const {}]);
}

/// A durable entity state, including tombstones that have no domain value.
class SyncStoredEntity<T> {
  const SyncStoredEntity({
    required this.value,
    required this.clock,
    required this.nodeId,
    required this.deleted,
    this.fieldMetadata = const {},
  });

  final T? value;
  final VectorClock clock;
  final String nodeId;
  final bool deleted;
  final Map<String, FieldLwwMetadata> fieldMetadata;
}

/// Optional durable acknowledgement support used by `SyncEngine.sync()`.
abstract class SyncAcknowledgementStorage {
  Future<void> recordAcknowledgements(
      List<ReplicaAcknowledgement> acknowledgements);
  Future<void> pruneAcknowledgedFrontiers();
}

/// Server-facing contract implemented by pluggable transport adapters.
abstract class SyncTransport {
  Future<SyncBatch> pull({required String lastSyncToken});
  Future<SyncResult> push(List<SyncOperation> operations);
  Stream<SyncNotification> get notifications;
}

class SyncBatch {
  const SyncBatch({
    this.operations = const [],
    this.nextSyncToken = '',
    this.acknowledgements = const [],
  });

  final List<SyncOperation> operations;
  final String nextSyncToken;
  final List<ReplicaAcknowledgement> acknowledgements;
}

/// A replica acknowledgement for a persisted entity vector clock.
class ReplicaAcknowledgement {
  const ReplicaAcknowledgement({
    required this.entityType,
    required this.entityId,
    required this.nodeId,
    required this.acknowledgedClock,
  });

  final String entityType;
  final String entityId;
  final String nodeId;
  final VectorClock acknowledgedClock;
}

class SyncNotification {
  const SyncNotification({this.syncToken});

  final String? syncToken;
}

enum SyncDisposition { accepted, rejected, conflict }

class SyncOperationResult {
  const SyncOperationResult({
    required this.operation,
    required this.disposition,
    this.updatedVectorClock,
    this.reason,
  });

  final SyncOperation operation;
  final SyncDisposition disposition;
  final VectorClock? updatedVectorClock;
  final String? reason;
}

class SyncResult {
  const SyncResult({this.results = const [], this.acknowledgements = const []});

  final List<SyncOperationResult> results;
  final List<ReplicaAcknowledgement> acknowledgements;

  factory SyncResult.accepted(List<SyncOperation> operations) => SyncResult(
        results: [
          for (final operation in operations)
            SyncOperationResult(
              operation: operation,
              disposition: SyncDisposition.accepted,
            ),
        ],
      );
}
