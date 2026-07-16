import 'package:sync_engine/sync_engine.dart';

part 'todo.sync.dart';

@Syncable()
class Todo {
  const Todo({required this.id, required this.title});

  @Id()
  final String id;

  @ConflictStrategy(ConflictType.lastWriteWins)
  final String title;
}
