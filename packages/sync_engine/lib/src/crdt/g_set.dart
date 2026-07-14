import 'dart:collection';

/// A grow-only set. Elements can be added and merged but never removed.
class GSet<T> {
  GSet([Set<T>? elements]) : _elements = Set.unmodifiable(elements ?? const {});

  final Set<T> _elements;

  /// A read-only view of the elements.
  Set<T> get value => UnmodifiableSetView(_elements);

  /// Returns a new set containing [element].
  GSet<T> add(T element) => GSet({..._elements, element});

  /// Merges sets using their union.
  GSet<T> merge(GSet<T> other) => GSet({..._elements, ...other._elements});

  /// Whether this set contains [element].
  bool contains(T element) => _elements.contains(element);

  @override
  bool operator ==(Object other) =>
      other is GSet<T> &&
      _elements.length == other._elements.length &&
      _elements.containsAll(other._elements);

  @override
  int get hashCode => Object.hashAllUnordered(_elements);

  @override
  String toString() => 'GSet($_elements)';
}
