import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_app/todo.dart';

void main() {
  test('consumer-owned Todo has a generated public adapter', () {
    const todo = Todo(id: 'todo-1', title: 'Try SyncForge');
    expect(const TodoSyncAdapter().idOf(todo), 'todo-1');
  });
}
