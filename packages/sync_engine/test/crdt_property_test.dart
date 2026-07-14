import 'dart:math';

import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

void main() {
  group('GCounter merge laws (1000 randomized iterations)', () {
    final random = Random(20260714);

    test('commutativity, associativity, idempotency, and identity', () {
      for (var i = 0; i < 1000; i++) {
        final a = _counter(random);
        final b = _counter(random);
        final c = _counter(random);
        final zero = GCounter();
        expect(a.merge(b), b.merge(a), reason: 'iteration $i: commutativity');
        expect(a.merge(b.merge(c)), a.merge(b).merge(c),
            reason: 'iteration $i: associativity');
        expect(a.merge(a), a, reason: 'iteration $i: idempotency');
        expect(a.merge(zero), a, reason: 'iteration $i: identity');
      }
    });
  });

  group('GSet merge laws (1000 randomized iterations)', () {
    final random = Random(20260715);

    test('commutativity, associativity, idempotency, and identity', () {
      for (var i = 0; i < 1000; i++) {
        final a = _set(random);
        final b = _set(random);
        final c = _set(random);
        final zero = GSet<int>();
        expect(a.merge(b), b.merge(a), reason: 'iteration $i: commutativity');
        expect(a.merge(b.merge(c)), a.merge(b).merge(c),
            reason: 'iteration $i: associativity');
        expect(a.merge(a), a, reason: 'iteration $i: idempotency');
        expect(a.merge(zero), a, reason: 'iteration $i: identity');
      }
    });
  });

  group('LWWRegister merge laws (1000 randomized iterations)', () {
    final random = Random(20260716);

    test('commutativity, associativity, and idempotency for valid writes', () {
      for (var i = 0; i < 1000; i++) {
        final a = _register(random, 'a');
        final b = _register(random, 'b');
        final c = _register(random, 'c');
        expect(a.merge(b), b.merge(a), reason: 'iteration $i: commutativity');
        expect(a.merge(b.merge(c)), a.merge(b).merge(c),
            reason: 'iteration $i: associativity');
        expect(a.merge(a), a, reason: 'iteration $i: idempotency');
      }
    });
  });
}

GCounter _counter(Random random) {
  var result = GCounter();
  for (final node in const ['a', 'b', 'c', 'd']) {
    result = result.increment(node, random.nextInt(50));
  }
  return result;
}

GSet<int> _set(Random random) => GSet({
      for (var i = 0; i < 12; i++)
        if (random.nextBool()) i
    });

LWWRegister<int> _register(Random random, String nodeId) {
  // Every generated register has a distinct writer ID, avoiding an invalid
  // duplicate write (same timestamp and node ID but different value).
  final clock = VectorClock({
    'a': random.nextInt(10),
    'b': random.nextInt(10),
    'c': random.nextInt(10),
  });
  return LWWRegister(
      value: random.nextInt(1000), timestamp: clock, nodeId: nodeId);
}
