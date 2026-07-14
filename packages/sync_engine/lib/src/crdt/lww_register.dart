import '../vector_clock.dart';

/// A last-write-wins register with a vector-clock timestamp.
///
/// Causally newer writes win. Concurrent writes are resolved by choosing the
/// lexicographically greater node ID. That tie-breaker is deterministic but
/// arbitrary and applications must decide whether it matches their domain.
///
/// The register retains its concurrent frontier internally. This is necessary
/// for associative merges: discarding a losing concurrent candidate too early
/// can change the outcome when a third replica is merged later.
class LWWRegister<T> {
  LWWRegister({
    required T value,
    required VectorClock timestamp,
    required String nodeId,
  })  : assert(nodeId != ''),
        _frontier = [_Version(value, timestamp, nodeId)],
        value = value,
        timestamp = timestamp,
        nodeId = nodeId;

  LWWRegister._(this._frontier)
      : assert(_frontier.isNotEmpty),
        value = _winner(_frontier).value,
        timestamp = _winner(_frontier).timestamp,
        nodeId = _winner(_frontier).nodeId;

  final List<_Version<T>> _frontier;
  final T value;
  final VectorClock timestamp;
  final String nodeId;

  /// Creates a new register value with its associated causal timestamp.
  LWWRegister<T> write(
          T newValue, VectorClock newTimestamp, String newNodeId) =>
      LWWRegister(value: newValue, timestamp: newTimestamp, nodeId: newNodeId);

  /// Merges two registers using a causally maximal frontier and then the
  /// documented node-ID tie-breaker to select its visible value.
  LWWRegister<T> merge(LWWRegister<T> other) {
    final candidates = [..._frontier, ...other._frontier];
    _rejectConflictingDuplicates(candidates);
    final frontier = <_Version<T>>[];
    for (final candidate in candidates) {
      if (frontier.any((existing) => _sameVersion(existing, candidate))) {
        continue;
      }
      final isDominated = candidates.any(
        (otherCandidate) =>
            candidate.timestamp.happenedBefore(otherCandidate.timestamp),
      );
      if (!isDominated) frontier.add(candidate);
    }
    return LWWRegister._(frontier);
  }

  @override
  bool operator ==(Object other) =>
      other is LWWRegister<T> &&
      _frontier.length == other._frontier.length &&
      _frontier.every((candidate) => other._frontier
          .any((otherCandidate) => _sameVersion(candidate, otherCandidate)));

  @override
  int get hashCode =>
      Object.hashAllUnordered(_frontier.map((candidate) => candidate.hashCode));

  @override
  String toString() =>
      'LWWRegister(value: $value, timestamp: $timestamp, nodeId: $nodeId)';

  static _Version<T> _winner<T>(List<_Version<T>> candidates) =>
      candidates.reduce((winner, candidate) =>
          winner.nodeId.compareTo(candidate.nodeId) < 0 ? candidate : winner);

  static bool _sameVersion<T>(_Version<T> a, _Version<T> b) =>
      a.nodeId == b.nodeId && a.timestamp == b.timestamp && a.value == b.value;

  static void _rejectConflictingDuplicates<T>(List<_Version<T>> candidates) {
    for (var index = 0; index < candidates.length; index++) {
      for (var otherIndex = index + 1;
          otherIndex < candidates.length;
          otherIndex++) {
        final left = candidates[index];
        final right = candidates[otherIndex];
        if (left.nodeId == right.nodeId &&
            left.timestamp == right.timestamp &&
            left.value != right.value) {
          throw StateError(
              'Conflicting LWW writes have identical node ID and timestamp.');
        }
      }
    }
  }
}

class _Version<T> {
  const _Version(this.value, this.timestamp, this.nodeId);

  final T value;
  final VectorClock timestamp;
  final String nodeId;

  @override
  bool operator ==(Object other) =>
      other is _Version<T> &&
      value == other.value &&
      timestamp == other.timestamp &&
      nodeId == other.nodeId;

  @override
  int get hashCode => Object.hash(value, timestamp, nodeId);
}
