import 'package:sync_engine/sync_engine.dart';

part 'invalid_task.sync.dart';

@Syncable()
class InvalidTask {
  const InvalidTask({required this.firstId, required this.secondId});

  @Id()
  final String firstId;

  @Id()
  final String secondId;
}
