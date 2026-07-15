import 'package:drift/drift.dart';
import 'package:sync_engine/sync_engine.dart';

part 'task.sync.dart';

@Syncable()
class Task {
  const Task({required this.id, required this.title});
  @Id()
  final String id;
  final String title;
}
