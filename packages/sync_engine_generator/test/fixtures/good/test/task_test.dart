@Tags(['fixture'])

import 'package:sync_engine/sync_engine.dart';
import 'package:sync_engine_generator_good_fixture/task.dart';
import 'package:test/test.dart';

void main() {
  test('generated adapter uses LWW and GSet CRDT merges', () {
    const adapter = TaskSyncAdapter();
    final left = adapter.toModel(
      const Task(id: 'task', title: 'from a', tags: {'one'}),
      VectorClock({'a': 1}),
      'a',
      {
        'id': FieldLwwMetadata(timestamp: VectorClock({'a': 1}), nodeId: 'a'),
        'title': FieldLwwMetadata(timestamp: VectorClock({'a': 1}), nodeId: 'a')
      },
    );
    final right = adapter.toModel(
      const Task(id: 'task', title: 'from b', tags: {'two'}),
      VectorClock({'b': 1}),
      'b',
      {
        'id': FieldLwwMetadata(timestamp: VectorClock({'b': 1}), nodeId: 'b'),
        'title': FieldLwwMetadata(timestamp: VectorClock({'b': 1}), nodeId: 'b')
      },
    );

    final merged = adapter.mergeModels(left, right);

    expect(merged.title, 'from b');
    expect(merged.tags, GSet({'one'}).merge(GSet({'two'})).value);
    expect(
      TaskSerializer()
          .fromJson(TaskSerializer()
              .toJson(const Task(id: 'task', title: 'title', tags: {'tag'})))
          .tags,
      {'tag'},
    );
  });
}
