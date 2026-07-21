import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_engine/sync_engine.dart';

import 'note.dart';
import 'note_storage.dart';
import 'note_transport.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = NoteStorage(await SharedPreferences.getInstance());
  await storage.initialize();
  runApp(NotesApp(storage: storage));
}

class NotesApp extends StatefulWidget {
  const NotesApp({super.key, required this.storage});
  final NoteStorage storage;

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  final _transport = NoteTransport();
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final SyncEngine _engine;
  final _conflicts = <ConflictResolution>[];
  StreamSubscription<ConflictResolution>? _subscription;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _engine = SyncEngine(
      storage: widget.storage,
      transport: _transport,
      nodeId: 'notes-demo-device',
      adapters: {Note: const NoteSyncAdapter()},
    );
    _subscription = _engine.conflicts.listen(
      (event) => setState(() => _conflicts.add(event)),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _engine.dispose();
    _transport.dispose();
    widget.storage.dispose();
    super.dispose();
  }

  Future<void> _edit([Note? note]) async {
    final materialContext = _navigatorKey.currentContext;
    if (materialContext == null) return;

    final title = TextEditingController(text: note?.title);
    final body = TextEditingController(text: note?.body);
    final result = await showDialog<Note>(
      context: materialContext,
      builder: (context) => AlertDialog(
        title: Text(note == null ? 'New note' : 'Edit note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: body,
              decoration: const InputDecoration(labelText: 'Body'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              Note(
                id:
                    note?.id ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                title: title.text,
                body: body.text,
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    if (note == null) {
      await _engine.insert(result);
    } else {
      await _engine.update(result);
    }
    if (!_offline) await _engine.sync();
  }

  Future<void> _sync() async {
    try {
      await _engine.sync();
    } catch (_) {
      if (mounted) {
        final materialContext = _navigatorKey.currentContext;
        if (materialContext == null || !materialContext.mounted) return;
        ScaffoldMessenger.of(materialContext).showSnackBar(
          const SnackBar(content: Text('Offline: operation remains queued.')),
        );
      }
    }
    if (mounted) setState(() {});
  }

  void _showConflicts() {
    final materialContext = _navigatorKey.currentContext;
    if (materialContext == null) return;

    showModalBottomSheet<void>(
      context: materialContext,
      builder: (context) => ListView(
        children: [
          const ListTile(title: Text('Conflict log')),
          for (final conflict in _conflicts)
            ListTile(title: Text(conflict.reason)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigatorKey,
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Offline notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync now',
            onPressed: _sync,
          ),
          IconButton(
            icon: const Icon(Icons.warning_amber),
            tooltip: 'Simulate conflict',
            onPressed: () => setState(() => _transport.rejectNextWrite = true),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Conflict log',
            onPressed: _showConflicts,
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: Text(_offline ? 'Offline mode' : 'Online mode'),
            value: _offline,
            onChanged: (value) => setState(() {
              _offline = value;
              _transport.online = !value;
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Pending operations: ${_engine.outbox.pendingOperations.length} · ${_offline ? 'Waiting to sync' : 'Ready'}',
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: _engine.watch<Note>(),
              builder: (context, snapshot) {
                final notes = snapshot.data ?? const <Note>[];
                return ListView(
                  children: [
                    for (final note in notes)
                      ListTile(
                        title: Text(note.title),
                        subtitle: Text(note.body),
                        onTap: () => _edit(note),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await _engine.delete<Note>(note.id);
                            if (!_offline) await _sync();
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _edit,
        child: const Icon(Icons.add),
      ),
    ),
  );
}
