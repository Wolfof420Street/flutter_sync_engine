import 'package:sync_engine/sync_engine.dart';

part 'task.sync.dart';

@Syncable()
class Task {
  const Task({required this.id, required this.title, this.completed = false});

  @Id()
  final String id;

  @ConflictStrategy(ConflictType.lastWriteWins)
  final String title;

  @ConflictStrategy(ConflictType.lastWriteWins)
  final bool completed;

  Task copyWith({String? title, bool? completed}) => Task(
    id: id,
    title: title ?? this.title,
    completed: completed ?? this.completed,
  );
}
