import 'package:sync_engine/sync_engine.dart';

part 'note.sync.dart';

@Syncable()
class Note {
  const Note({required this.id, required this.title, this.body = ''});

  @Id()
  final String id;

  @ConflictStrategy(ConflictType.lastWriteWins)
  final String title;

  @ConflictStrategy(ConflictType.lastWriteWins)
  final String body;

  Note copyWith({String? title, String? body}) =>
      Note(id: id, title: title ?? this.title, body: body ?? this.body);
}
