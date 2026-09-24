import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sync_engine/sync_engine.dart';

import 'playground_relay.dart';
import 'playground_storage.dart';
import 'playground_task.dart';

void main() => runApp(const ConflictPlaygroundApp());

class ConflictPlaygroundApp extends StatefulWidget {
  const ConflictPlaygroundApp({super.key, this.controller});

  final ConflictPlaygroundController? controller;

  @override
  State<ConflictPlaygroundApp> createState() => _ConflictPlaygroundAppState();
}

class _ConflictPlaygroundAppState extends State<ConflictPlaygroundApp> {
  late final ConflictPlaygroundController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ConflictPlaygroundController();
    _controller.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    await action();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('SyncForge Conflict Playground'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Chip(
                    avatar: Icon(
                      _controller.online ? Icons.cloud_done : Icons.cloud_off,
                    ),
                    label: Text(_controller.online ? 'ONLINE' : 'OFFLINE'),
                  ),
                ),
              ),
            ],
          ),
          body: !_ready
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Two devices edit the same task while disconnected. '
                      'SyncForge uses the generated adapter and real CRDT merge engine to converge.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            key: const Key('offline-edits'),
                            onPressed: () => _run(_controller.makeOfflineEdits),
                            icon: const Icon(Icons.edit_off),
                            label: const Text('1. Make offline edits'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            key: const Key('sync-devices'),
                            onPressed: () => _run(_controller.syncDevices),
                            icon: const Icon(Icons.sync),
                            label: const Text('2. Sync devices'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _DeviceCard(
                            label: 'DEVICE A',
                            color: Colors.blue,
                            task: _controller.deviceATask,
                            clock: _controller.deviceAClock,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DeviceCard(
                            label: 'DEVICE B',
                            color: Colors.orange,
                            task: _controller.deviceBTask,
                            clock: _controller.deviceBClock,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MERGED RESULT',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Title: ${_controller.mergedTitle}'),
                            Text('Details: ${_controller.mergedDetails}'),
                            const SizedBox(height: 8),
                            Text(
                              _controller.synced
                                  ? 'Resolved deterministically — title winner: Device B; Device A details preserved.'
                                  : 'Waiting for the two devices to sync.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('CONFLICT HISTORY',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    if (_controller.history.isEmpty)
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('No conflicts yet — make the offline edits.'),
                        ),
                      ),
                    for (final event in _controller.history)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.merge_type),
                          title: Text(event),
                        ),
                      ),
                  ],
                ),
        ),
      );
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.label,
    required this.color,
    required this.task,
    required this.clock,
  });

  final String label;
  final Color color;
  final PlaygroundTask? task;
  final VectorClock? clock;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const Divider(),
              Text('Title: ${task?.title ?? '—'}'),
              Text('Details: ${task?.details ?? '—'}'),
              const SizedBox(height: 8),
              Text('Clock: ${clock ?? '—'}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}

/// Drives a repeatable two-device scenario through real [SyncEngine]s.
class ConflictPlaygroundController {
  ConflictPlaygroundController() {
    _transportA = _relay.connect();
    _transportB = _relay.connect();
    _engineA = SyncEngine(
      storage: _storageA,
      transport: _transportA,
      nodeId: 'device-a',
      adapters: {PlaygroundTask: const PlaygroundTaskSyncAdapter()},
    );
    _engineB = SyncEngine(
      storage: _storageB,
      transport: _transportB,
      nodeId: 'device-b',
      adapters: {PlaygroundTask: const PlaygroundTaskSyncAdapter()},
    );
    _subscriptions.add(_engineA.conflicts.listen((event) =>
        history.add('Device A: ${event.reason}')));
    _subscriptions.add(_engineB.conflicts.listen((event) =>
        history.add('Device B: ${event.reason}')));
  }

  static const _taskId = 'grocery-task';
  final _relay = PlaygroundRelay();
  final _storageA = PlaygroundStorage();
  final _storageB = PlaygroundStorage();
  final history = <String>[];
  final _subscriptions = <StreamSubscription<ConflictResolution>>[];
  late final PlaygroundTransport _transportA;
  late final PlaygroundTransport _transportB;
  late final SyncEngine _engineA;
  Future<void>? _initialization;
  late final SyncEngine _engineB;
  bool synced = false;

  bool get online => _relay.online;
  PlaygroundTask? get deviceATask =>
      _storageA.record(_taskId)?.value as PlaygroundTask?;
  PlaygroundTask? get deviceBTask =>
      _storageB.record(_taskId)?.value as PlaygroundTask?;
  VectorClock? get deviceAClock => _storageA.record(_taskId)?.clock;
  VectorClock? get deviceBClock => _storageB.record(_taskId)?.clock;
  String get mergedTitle => synced ? deviceATask?.title ?? '—' : '—';
  String get mergedDetails => synced ? deviceATask?.details ?? '—' : '—';

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    await _storageA.initialize();
    await _storageB.initialize();
    await _engineA.insert(const PlaygroundTask(
      id: _taskId,
      title: 'Buy groceries',
      details: 'Shared starting task',
    ));
    await _syncRound();
    _relay.online = false;
  }

  Future<void> makeOfflineEdits() async {
    _relay.online = false;
    synced = false;
    history.clear();
    await _engineA.update(deviceATask!.copyWith(
      title: 'Buy milk',
      details: 'Oat milk is fine',
    ));
    await _engineB.update(deviceBTask!.copyWith(title: 'Buy eggs'));
  }

  Future<void> syncDevices() async {
    _relay.online = true;
    await _syncRound();
    synced = true;
  }

  Future<void> _syncRound() async {
    await _engineA.sync();
    await _engineB.sync();
    await _engineA.sync();
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _engineA.dispose();
    await _engineB.dispose();
    await _transportA.dispose();
    await _transportB.dispose();
    await _storageA.dispose();
    await _storageB.dispose();
  }
}
