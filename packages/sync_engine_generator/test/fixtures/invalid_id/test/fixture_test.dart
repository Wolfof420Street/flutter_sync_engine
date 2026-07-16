@Tags(['fixture'])

import 'package:test/test.dart';

void main() {
  test('invalid fixture is reserved for build-runner validation', () {
    expect(true, isTrue);
  });
}
