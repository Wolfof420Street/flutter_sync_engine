import 'package:sync_engine/sync_engine.dart';

part 'task.sync.dart';

@Syncable()
class Task {
  const Task({required this.id, required this.title, required this.tags});

  @Id()
  final String id;

  @ConflictStrategy(ConflictType.lastWriteWins)
  final String title;

  @ConflictStrategy(ConflictType.growOnlySet)
  final Set<String> tags;
}
