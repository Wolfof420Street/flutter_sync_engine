import 'dart:convert';

import 'package:drift_bootstrap_fixture/task.dart';

void main() {
  print(jsonEncode(const TaskSerializer().toJson(
    const Task(id: 'task-1', title: 'Kept'),
  )));
}
