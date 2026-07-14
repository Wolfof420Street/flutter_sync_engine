import 'dart:collection';

/// An immutable vector clock used to establish causal ordering between events.
class VectorClock {
  /// Creates a clock from node counters. Counters must be non-negative.
  VectorClock([Map<String, int>? clocks])
      : _clocks = Map.unmodifiable(_validate(clocks ?? const {}));

  final Map<String, int> _clocks;

  /// A read-only view of the counters, useful for serialization.
  Map<String, int> get clocks => UnmodifiableMapView(_clocks);

  /// Returns a new clock with [nodeId]'s counter incremented.
  VectorClock increment(String nodeId) {
    if (nodeId.isEmpty) {
      throw ArgumentError.value(nodeId, 'nodeId', 'must not be empty');
    }
    return VectorClock({..._clocks, nodeId: (_clocks[nodeId] ?? 0) + 1});
  }

  /// Returns an element-wise maximum of this clock and [other].
  VectorClock merge(VectorClock other) {
    final result = Map<String, int>.from(_clocks);
    for (final entry in other._clocks.entries) {
      result[entry.key] = _max(result[entry.key] ?? 0, entry.value);
    }
    return VectorClock(result);
  }

  /// Whether this clock causally precedes [other].
  bool happenedBefore(VectorClock other) => _strictlyLessThan(other);

  /// Whether this clock causally succeeds [other].
  bool happenedAfter(VectorClock other) => other.happenedBefore(this);

  /// Whether neither clock causally precedes the other.
  bool isConcurrent(VectorClock other) =>
      !equals(other) && !happenedBefore(other) && !happenedAfter(other);

  /// Serializes the clock as a JSON-compatible map.
  Map<String, int> toJson() => Map<String, int>.from(_clocks);

  /// Deserializes a clock from a JSON object.
  factory VectorClock.fromJson(Map<String, dynamic> json) => VectorClock(
        json.map((key, value) => MapEntry(key, _asCounter(key, value))),
      );

  /// Structural equality for clocks.
  bool equals(VectorClock other) {
    if (_clocks.length != other._clocks.length) return false;
    return _clocks.entries
        .every((entry) => other._clocks[entry.key] == entry.value);
  }

  bool _strictlyLessThan(VectorClock other) {
    var hasStrictlySmallerComponent = false;
    final nodeIds = {..._clocks.keys, ...other._clocks.keys};
    for (final nodeId in nodeIds) {
      final left = _clocks[nodeId] ?? 0;
      final right = other._clocks[nodeId] ?? 0;
      if (left > right) return false;
      if (left < right) hasStrictlySmallerComponent = true;
    }
    return hasStrictlySmallerComponent;
  }

  static Map<String, int> _validate(Map<String, int> source) {
    for (final entry in source.entries) {
      if (entry.key.isEmpty || entry.value < 0) {
        throw ArgumentError.value(source, 'clocks',
            'node IDs must be non-empty and counters non-negative');
      }
    }
    return Map<String, int>.from(source);
  }

  static int _asCounter(String key, dynamic value) {
    if (value is! int || value < 0) {
      throw FormatException(
          'Clock value for "$key" must be a non-negative integer.');
    }
    return value;
  }

  static int _max(int a, int b) => a > b ? a : b;

  @override
  bool operator ==(Object other) => other is VectorClock && equals(other);

  @override
  int get hashCode => Object.hashAllUnordered(
        _clocks.entries.map((entry) => Object.hash(entry.key, entry.value)),
      );

  @override
  String toString() => _clocks.toString();
}
