import 'package:drift_bootstrap_fixture/task.dart';
import 'package:test/test.dart';

void main() {
  test('generated pre-additive serializer emits the persisted legacy shape', () {
    expect(
      const TaskSerializer().toJson(const Task(id: 'task-1', title: 'Kept')),
      <String, dynamic>{'id': 'task-1', 'title': 'Kept'},
    );
  });
}
