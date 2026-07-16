@Tags(['fixture'])

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
      'build rejects the rename-shaped schema change with the documented error',
      () async {
    final result = await Process.run(
      Platform.resolvedExecutable,
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
