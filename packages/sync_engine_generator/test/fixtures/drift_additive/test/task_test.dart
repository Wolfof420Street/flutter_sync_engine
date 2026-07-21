@Tags(['fixture'])

import 'dart:convert';
import 'dart:io';

import 'package:drift_additive_fixture/task.dart';
import 'package:test/test.dart';

void main() {
  final dart = _dartExecutable();

  test('generated adapter restores a payload emitted by the legacy adapter',
      () async {
    final legacy = Directory('../drift_bootstrap');
    final build = await Process.run(
      dart,
      const <String>[
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ],
      workingDirectory: legacy.path,
    );
    expect(build.exitCode, 0, reason: '${build.stdout}${build.stderr}');

    final write = await Process.run(
      dart,
      const <String>[
        '--packages=.dart_tool/package_config.json',
        'bin/write_legacy_payload.dart',
      ],
      workingDirectory: legacy.path,
    );
    expect(write.exitCode, 0, reason: '${write.stdout}${write.stderr}');
    final payload = jsonDecode(write.stdout.trim()) as Map<String, dynamic>;
    expect(payload, <String, dynamic>{'id': 'task-1', 'title': 'Kept'});

    final restored = const TaskSerializer().fromJson(payload);

    expect(restored.id, 'task-1');
    expect(restored.title, 'Kept');
    expect(restored.completed, isFalse);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

String _dartExecutable() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    throw StateError('FLUTTER_ROOT is required to locate the Dart SDK.');
  }
  return '$flutterRoot/bin/cache/dart-sdk/bin/dart';
}
