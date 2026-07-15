/// Supplies the entity-specific details required by the generic sync engine.
abstract class SyncAdapter<T> {
  /// Stable type name sent to the transport.
  String get entityType;

  /// Extracts the stable identifier from [entity].
  String idOf(T entity);

  /// Converts an entity to a transport and persistence-safe JSON map.
  Map<String, dynamic> toJson(T entity);

  /// Restores an entity from a transport and persistence-safe JSON map.
  T fromJson(Map<String, dynamic> json);
}

/// Thrown when an operation is attempted for a type without an adapter.
class UnregisteredSyncTypeError extends StateError {
  UnregisteredSyncTypeError(Type type)
      : super(
            'No SyncAdapter is registered for type $type. Add @Syncable or register an adapter.');
}
