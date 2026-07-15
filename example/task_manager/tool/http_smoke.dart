import 'package:sync_engine/sync_engine.dart';
import 'package:task_manager/task.dart';
import 'package:task_manager/task_transport.dart';

Future<void> main() async {
  final transport = TaskTransport(Uri.parse('http://127.0.0.1:8080'));
  final result = await transport.push([
    InsertOperation(
      entityType: 'task',
      entityId: 'http-smoke',
      vectorClock: VectorClock({'smoke': 1}),
      entity: const Task(id: 'http-smoke', title: 'HTTP smoke'),
    ),
  ]);
  if (result.results.single.disposition != SyncDisposition.accepted) {
    throw StateError('Shelf server rejected HTTP smoke operation');
  }
  await transport.dispose();
}
