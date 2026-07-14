import 'dart:collection';

/// A grow-only counter. Each node owns and only advances its own component.
class GCounter {
  GCounter([Map<String, int>? payload])
      : _payload = Map.unmodifiable(_validate(payload ?? const {}));

  final Map<String, int> _payload;

  /// Read-only per-node components, primarily for diagnostics and persistence.
  Map<String, int> get payload => UnmodifiableMapView(_payload);

  /// The sum of all node components.
  int get value => _payload.values.fold(0, (sum, component) => sum + component);

  /// Returns a new counter with [delta] added to [nodeId]'s component.
  GCounter increment(String nodeId, [int delta = 1]) {
    if (nodeId.isEmpty || delta < 0) {
      throw ArgumentError(
          'nodeId must be non-empty and delta must be non-negative.');
    }
    return GCounter({..._payload, nodeId: (_payload[nodeId] ?? 0) + delta});
  }

  /// Merges counters using the maximum component for every node.
  GCounter merge(GCounter other) {
    final merged = Map<String, int>.from(_payload);
    for (final entry in other._payload.entries) {
      final current = merged[entry.key] ?? 0;
      merged[entry.key] = current > entry.value ? current : entry.value;
    }
    return GCounter(merged);
  }

  @override
  bool operator ==(Object other) => other is GCounter && _samePayload(other);

  bool _samePayload(GCounter other) =>
      _payload.length == other._payload.length &&
      _payload.entries
          .every((entry) => other._payload[entry.key] == entry.value);

  @override
  int get hashCode => Object.hashAllUnordered(
        _payload.entries.map((entry) => Object.hash(entry.key, entry.value)),
      );

  @override
  String toString() => 'GCounter($_payload)';

  static Map<String, int> _validate(Map<String, int> source) {
    if (source.entries.any((entry) => entry.key.isEmpty || entry.value < 0)) {
      throw ArgumentError.value(source, 'payload',
          'components must be non-negative and node IDs non-empty');
    }
    return Map<String, int>.from(source);
  }
}
