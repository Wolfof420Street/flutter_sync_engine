import 'dart:io';

import 'package:test/test.dart';

void main() {
  final dart = _dartExecutable();

  test('custom merge fields are rejected during generation', () async {
    final fixture = Directory('test/fixtures/custom_merge');

    final clean = await Process.run(
      dart,
      const <String>['run', 'build_runner', 'clean'],
      workingDirectory: fixture.path,
    );
    expect(clean.exitCode, 0, reason: '${clean.stdout}${clean.stderr}');

    final build = await Process.run(
      dart,
      const <String>[
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ],
      workingDirectory: fixture.path,
    );

    expect(build.exitCode, isNonZero);
    expect(
      '${build.stdout}${build.stderr}',
      contains(
        'ConflictType.custom',
      ),
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
}

String _dartExecutable() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    throw StateError('FLUTTER_ROOT is required to locate the Dart SDK.');
  }
  return '$flutterRoot/bin/cache/dart-sdk/bin/dart';
}
