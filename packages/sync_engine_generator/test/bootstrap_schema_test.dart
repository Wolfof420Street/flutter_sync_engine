import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final dart = _dartExecutable();

  test('writes a baseline once and refuses to overwrite it', () async {
    final directory = await Directory.systemTemp.createTemp('schema-bootstrap');
    addTearDown(() => directory.delete(recursive: true));

    final manifest = File('${directory.path}/sync_engine_schema.json');
    final script = File('bin/bootstrap_schema.dart').absolute.path;

    final first = await Process.run(
      dart,
      <String>[script, manifest.path, 'Task', 'id,title'],
    );

    expect(first.exitCode, 0);
    expect(jsonDecode(await manifest.readAsString()), <String, dynamic>{
      'Task': <String>['id', 'title'],
    });

    final second = await Process.run(
      dart,
      <String>[script, manifest.path, 'Task', 'id,title'],
    );

    expect(second.exitCode, 65);
    expect(second.stderr,
        contains('Manifest already contains a baseline for Task.'));
    expect(jsonDecode(await manifest.readAsString()), <String, dynamic>{
      'Task': <String>['id', 'title'],
    });
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('updates an existing baseline only when fields are additive', () async {
    final directory = await Directory.systemTemp.createTemp('schema-update');
    addTearDown(() => directory.delete(recursive: true));

    final manifest = File('${directory.path}/sync_engine_schema.json');
    await manifest.writeAsString('{"Task":["id","title"]}');
    final script = File('bin/update_schema.dart').absolute.path;

    final additive = await Process.run(
      dart,
      <String>[script, manifest.path, 'Task', 'id,title,completed'],
    );

    expect(additive.exitCode, 0);
    expect(jsonDecode(await manifest.readAsString()), <String, dynamic>{
      'Task': <String>['id', 'title', 'completed'],
    });

    final removal = await Process.run(
      dart,
      <String>[script, manifest.path, 'Task', 'id,completed'],
    );

    expect(removal.exitCode, 65);
    expect(
      removal.stderr,
      contains(
        'Additive-only Drift migration rejected for Task: removed or renamed field(s) title.',
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
