import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

void main() {
  test('LWW register chooses a causally newer value', () {
    final old = LWWRegister(
        value: 'old', timestamp: VectorClock({'a': 1}), nodeId: 'a');
    final newer = LWWRegister(
        value: 'new', timestamp: VectorClock({'a': 2}), nodeId: 'a');
    expect(old.merge(newer), newer);
  });

  test('LWW register uses lexicographic node ID for concurrent values', () {
    final fromA = LWWRegister(
        value: 'from a', timestamp: VectorClock({'a': 1}), nodeId: 'a');
    final fromB = LWWRegister(
        value: 'from b', timestamp: VectorClock({'b': 1}), nodeId: 'b');
    final merged = fromA.merge(fromB);
    expect(merged.value, 'from b');
    expect(merged.timestamp, VectorClock({'b': 1}));
    expect(merged.nodeId, 'b');
    expect(fromB.merge(fromA).value, 'from b');
  });

  test('preserves a four-way concurrent frontier across every merge order', () {
    final registers = <LWWRegister<String>>[
      LWWRegister(
          value: 'from a', timestamp: VectorClock({'a': 1}), nodeId: 'a'),
      LWWRegister(
          value: 'from b', timestamp: VectorClock({'b': 1}), nodeId: 'b'),
      LWWRegister(
          value: 'from c', timestamp: VectorClock({'c': 1}), nodeId: 'c'),
      LWWRegister(
          value: 'from d', timestamp: VectorClock({'d': 1}), nodeId: 'd'),
    ];

    for (final left in registers) {
      for (final right in registers) {
        if (identical(left, right)) continue;
        expect(left.timestamp.isConcurrent(right.timestamp), isTrue);
      }
    }

    final expected = _mergeInOrder(registers);
    for (final order in _permutations(registers)) {
      final result = _mergeInOrder(order);
      // LWWRegister equality includes the private frontier, so this asserts
      // that every causally maximal candidate survives every merge ordering.
      expect(result, expected,
          reason: 'order: ${order.map((item) => item.nodeId)}');
      expect(result.value, 'from d');
      expect(result.nodeId, 'd');
      expect(result.timestamp, VectorClock({'d': 1}));
    }
  });

  test('rejects corrupt duplicate writes with different values', () {
    final first = LWWRegister(
        value: 'one', timestamp: VectorClock({'a': 1}), nodeId: 'a');
    final duplicate = LWWRegister(
        value: 'two', timestamp: VectorClock({'a': 1}), nodeId: 'a');
    expect(() => first.merge(duplicate), throwsStateError);
  });
}

LWWRegister<String> _mergeInOrder(List<LWWRegister<String>> registers) =>
    registers.reduce((merged, next) => merged.merge(next));

Iterable<List<T>> _permutations<T>(List<T> values) sync* {
  if (values.length <= 1) {
    yield values;
    return;
  }

  for (var index = 0; index < values.length; index++) {
    final first = values[index];
    final remaining = [...values]..removeAt(index);
    for (final suffix in _permutations(remaining)) {
      yield [first, ...suffix];
    }
  }
}
