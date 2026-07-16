import 'package:sync_engine/sync_engine.dart';

part 'playground_task.sync.dart';

@Syncable()
class PlaygroundTask {
  const PlaygroundTask({
    required this.id,
    required this.title,
    required this.details,
  });

  @Id()
  final String id;

  @ConflictStrategy(ConflictType.lastWriteWins)
  final String title;

  @ConflictStrategy(ConflictType.lastWriteWins)
  final String details;

  PlaygroundTask copyWith({String? title, String? details}) => PlaygroundTask(
        id: id,
        title: title ?? this.title,
        details: details ?? this.details,
      );
}
