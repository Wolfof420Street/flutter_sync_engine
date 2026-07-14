/// Marks a domain class for synchronization model and adapter generation.
class Syncable {
  const Syncable();
}

/// Marks the one String field that uniquely identifies a synchronized entity.
class Id {
  const Id();
}

/// Built-in merge strategies understood by the synchronization generator.
enum ConflictType { lastWriteWins, growOnlyCounter, growOnlySet, custom }

/// Selects the merge strategy for a synchronized field.
class ConflictStrategy {
  const ConflictStrategy(this.type);

  final ConflictType type;
}
