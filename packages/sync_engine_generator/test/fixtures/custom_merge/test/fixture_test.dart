@Tags(['fixture'])

import 'package:test/test.dart';

void main() {
  test('custom merge fixture is reserved for build-runner validation', () {
    expect(true, isTrue);
  });
}
