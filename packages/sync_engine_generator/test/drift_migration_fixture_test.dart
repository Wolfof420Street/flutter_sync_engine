import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final dart = Platform.resolvedExecutable;
  final bootstrap = Directory('test/fixtures/drift_bootstrap');
  final additive = Directory('test/fixtures/drift_additive');
  final removal = Directory('test/fixtures/drift_remove');

  Future<ProcessResult> build(Directory fixture) async {
    final clean = await Process.run(
      dart,
      const <String>['run', 'build_runner', 'clean'],
      workingDirectory: fixture.path,
    );
    if (clean.exitCode != 0) return clean;

    return Process.run(
      dart,
      const <String>[
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ],
      workingDirectory: fixture.path,
    );
  }

  Future<ProcessResult> runScript(
    String script,
    Directory fixture,
    List<String> arguments,
  ) =>
      Process.run(
        dart,
        <String>[script, ...arguments],
        workingDirectory: fixture.path,
      );

  test('bootstrap fixture builds with no manifest, then CLI writes one once',
      () async {
    final manifest = File('${bootstrap.path}/lib/sync_engine_schema.json');
    final generated = File('${bootstrap.path}/lib/task.sync.dart');
    final originalGenerated =
        generated.existsSync() ? await generated.readAsString() : null;
    if (manifest.existsSync()) await manifest.delete();
    if (generated.existsSync()) await generated.delete();
    addTearDown(() async {
      if (manifest.existsSync()) await manifest.delete();
      if (originalGenerated == null) {
        if (generated.existsSync()) await generated.delete();
      } else {
        await generated.writeAsString(originalGenerated);
      }
    });

    final buildResult = await build(bootstrap);
    expect(buildResult.exitCode, 0,
        reason: '${buildResult.stdout}${buildResult.stderr}');
    expect(generated.existsSync(), isTrue);
    expect(await generated.length(), greaterThan(0));

    final first = await runScript(
      '../../../bin/bootstrap_schema.dart',
      bootstrap,
      <String>['lib/sync_engine_schema.json', 'Task', 'id,title'],
    );
    expect(first.exitCode, 0, reason: '${first.stdout}${first.stderr}');
    expect(jsonDecode(await manifest.readAsString()), <String, dynamic>{
      'Task': <String>['id', 'title'],
    });

    final second = await runScript(
      '../../../bin/bootstrap_schema.dart',
      bootstrap,
      <String>['lib/sync_engine_schema.json', 'Task', 'id,title'],
    );
    expect(second.exitCode, 65);
    expect(second.stderr,
        contains('Manifest already contains a baseline for Task.'));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('additive fixture generates from its baseline and explicitly updates it',
      () async {
    final manifest = File('${additive.path}/lib/sync_engine_schema.json');
    await manifest.writeAsString('{"Task":["id","title"]}\n');
    final generated = File('${additive.path}/lib/task.sync.dart');
    if (generated.existsSync()) await generated.delete();

    final buildResult = await build(additive);
    expect(buildResult.exitCode, 0,
        reason: '${buildResult.stdout}${buildResult.stderr}');
    expect(generated.existsSync(), isTrue);
    expect(await generated.length(), greaterThan(0));

    final update = await runScript(
      '../../../bin/update_schema.dart',
      additive,
      <String>['lib/sync_engine_schema.json', 'Task', 'id,title,completed'],
    );
    expect(update.exitCode, 0, reason: '${update.stdout}${update.stderr}');
    expect(jsonDecode(await manifest.readAsString()), <String, dynamic>{
      'Task': <String>['id', 'title', 'completed'],
    });
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('rename-shaped fixture rejects the removed baseline field', () async {
    final manifest = File('${removal.path}/lib/sync_engine_schema.json');
    await manifest.writeAsString('{"Task":["id","title","tags"]}\n');

    final buildResult = await build(removal);
    expect(buildResult.exitCode, isNonZero);
    expect(
      '${buildResult.stdout}${buildResult.stderr}',
      contains(
        'Additive-only Drift migration rejected for Task: removed or renamed field(s) tags.',
      ),
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
