import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

void main() {
  group('VectorClock', () {
    test('is immutable when incremented and merged', () {
      final original = VectorClock({'a': 1});
      expect(original.increment('a'), VectorClock({'a': 2}));
      expect(original, VectorClock({'a': 1}));
      expect(
          original.merge(VectorClock({'b': 3})), VectorClock({'a': 1, 'b': 3}));
    });

    test('compares equal clocks', () {
      final a = VectorClock({'a': 2, 'b': 1});
      final b = VectorClock({'a': 2, 'b': 1});
      expect(a.happenedBefore(b), isFalse);
      expect(a.happenedAfter(b), isFalse);
      expect(a.isConcurrent(b), isFalse);
    });

    test('compares causal order including missing components', () {
      final before = VectorClock({'a': 1});
      final after = VectorClock({'a': 2, 'b': 1});
      expect(before.happenedBefore(after), isTrue);
      expect(after.happenedAfter(before), isTrue);
    });

    test('identifies concurrent clocks', () {
      final left = VectorClock({'a': 2, 'b': 1});
      final right = VectorClock({'a': 1, 'b': 2});
      expect(left.isConcurrent(right), isTrue);
    });

    test('round-trips JSON', () {
      final clock = VectorClock({'one': 1, 'two': 5});
      expect(VectorClock.fromJson(clock.toJson()), clock);
    });
  });
}
