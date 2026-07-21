@Tags(['fixture'])

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final dart = _dartExecutable();

  test(
      'build rejects the rename-shaped schema change with the documented error',
      () async {
    final result = await Process.run(
      dart,
      const <String>[
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ],
    );

    expect(result.exitCode, isNonZero);
    expect(
      '${result.stdout}${result.stderr}',
      contains(
        'Additive-only Drift migration rejected for Task: removed or renamed field(s) tags.',
      ),
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}

String _dartExecutable() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    throw StateError('FLUTTER_ROOT is required to locate the Dart SDK.');
  }
  return '$flutterRoot/bin/cache/dart-sdk/bin/dart';
}
