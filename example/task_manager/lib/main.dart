import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sync_engine/sync_engine.dart';

import 'task.dart';
import 'task_storage.dart';
import 'task_transport.dart';

void main() => runApp(const TaskManagerApp());

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key, this.transport});

  /// Test/demo injection point. Production defaults to localhost Shelf HTTP.
  final TaskTransport? transport;

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  late final TaskStorage _storage;
  late final TaskTransport _transport;
  late final SyncEngine _engine;
  final _conflicts = <ConflictResolution>[];
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<ConflictResolution>? _conflictSubscription;

  @override
  void initState() {
    super.initState();
    _storage = TaskStorage();
    _transport =
        widget.transport ?? TaskTransport(Uri.parse('http://127.0.0.1:8080'));
    _engine = SyncEngine(
      storage: _storage,
      transport: _transport,
      nodeId: 'task-manager',
    );
    registerTaskSyncAdapter(_engine);
    _conflictSubscription = _engine.conflicts.listen((event) {
      setState(() => _conflicts.insert(0, event));
    });
  }

  @override
  void dispose() {
    unawaited(_conflictSubscription?.cancel() ?? Future<void>.value());
    unawaited(_engine.dispose());
    unawaited(_transport.dispose());
    unawaited(_storage.dispose());
    super.dispose();
  }

  Future<void> _sync() async {
    try {
      await _engine.sync();
    } catch (_) {
      // The outbox retains operations and applies its configured retry policy.
    }
    if (mounted) setState(() {});
  }

  Future<void> _addTask() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: _navigatorKey.currentContext!,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add task'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty) {
      return;
    }
    await _engine.insert(
      Task(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title.trim(),
      ),
    );
    await _sync();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigatorKey,
    title: 'Offline Tasks',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Offline tasks'),
        actions: [
          IconButton(
            onPressed: _sync,
            icon: const Icon(Icons.sync),
            tooltip: 'Sync now',
          ),
          IconButton(
            icon: Badge(
              label: Text('${_conflicts.length}'),
              child: const Icon(Icons.warning_amber_rounded),
            ),
            onPressed: _showConflicts,
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: Text(
              _transport.online
                  ? 'Online — Shelf HTTP enabled'
                  : 'Offline simulation — operations queue',
            ),
            value: _transport.online,
            onChanged: (value) => setState(() => _transport.online = value),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Pending: ${_engine.outbox.pendingOperations.length}  •  Dead letters: ${_engine.outbox.deadLetters.length}',
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _engine.watch<Task>(),
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? const <Task>[];
                if (tasks.isEmpty) {
                  return const Center(
                    child: Text('Add a task while offline, then sync it.'),
                  );
                }
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return CheckboxListTile(
                      value: task.completed,
                      title: Text(task.title),
                      onChanged: (value) async {
                        await _engine.update(task.copyWith(completed: value));
                        await _sync();
                      },
                      secondary: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await _engine.delete<Task>(task.id);
                          await _sync();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    ),
  );

  void _showConflicts() => showModalBottomSheet<void>(
    context: _navigatorKey.currentContext!,
    builder: (context) => ListView(
      children: [
        const ListTile(title: Text('Conflict / rollback log')),
        for (final conflict in _conflicts)
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded),
            title: Text(conflict.reason),
            subtitle: Text(
              '${conflict.operation.entityType}/${conflict.operation.entityId}',
            ),
          ),
      ],
    ),
  );
}
