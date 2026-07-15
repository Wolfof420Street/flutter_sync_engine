import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:task_manager/task.dart';
import 'package:task_manager/task_transport.dart';

void main() {
  test(
    'TaskTransport round-trips an operation through the Shelf server',
    () async {
      final server = await Process.start(
        Platform.resolvedExecutable,
        const <String>[
          '--packages=.dart_tool/package_config.json',
          'bin/mock_server.dart',
        ],
      );
      addTearDown(() async {
        server.kill(ProcessSignal.sigterm);
        await server.exitCode;
      });

      await server.stdout
          .transform(const SystemEncoding().decoder)
          .firstWhere((line) => line.contains('listening on'))
          .timeout(const Duration(seconds: 10));

      final transport = TaskTransport(Uri.parse('http://127.0.0.1:8080'));
      addTearDown(transport.dispose);
      final result = await transport.push([
        InsertOperation(
          entityType: 'task',
          entityId: 'http-task',
          vectorClock: VectorClock({'http-test': 1}),
          entity: const Task(id: 'http-task', title: 'HTTP boundary'),
        ),
      ]);

      expect(result.results.single.disposition, SyncDisposition.accepted);
      final batch = await transport.pull(lastSyncToken: '');
      expect(batch.nextSyncToken, isNotEmpty);
    },
    skip: Platform.environment['RUN_HTTP_INTEGRATION'] == 'true'
        ? false
        : 'requires localhost socket binding; run with RUN_HTTP_INTEGRATION=true',
  );
}
