import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:task_manager/main.dart';
import 'package:task_manager/task_transport.dart';

class _DemoTransport extends TaskTransport {
  _DemoTransport({this.rejectPushes = false})
    : super(Uri.parse('http://unused.test'));

  final bool rejectPushes;

  @override
  Future<SyncBatch> pull({required String lastSyncToken}) async {
    if (!online) throw StateError('Offline simulation is enabled');
    return const SyncBatch(nextSyncToken: 'demo-token');
  }

  @override
  Future<SyncResult> push(List<SyncOperation> operations) async {
    if (!online) throw StateError('Offline simulation is enabled');
    return SyncResult(
      results: [
        for (final operation in operations)
          SyncOperationResult(
            operation: operation,
            disposition: rejectPushes
                ? SyncDisposition.rejected
                : SyncDisposition.accepted,
            reason: rejectPushes ? 'Synthetic demo rejection' : null,
          ),
      ],
    );
  }
}

Future<void> _addTask(WidgetTester tester, String title) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pump();
  await tester.enterText(find.byType(TextField), title);
  await tester.tap(find.text('Add'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('queues offline work and flushes it after reconnect', (
    tester,
  ) async {
    final transport = _DemoTransport()..online = false;
    await tester.pumpWidget(TaskManagerApp(transport: transport));

    await _addTask(tester, 'Offline task');
    expect(find.textContaining('Pending: 1'), findsOneWidget);
    expect(find.text('Offline task'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.byTooltip('Sync now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Pending: 0'), findsOneWidget);
    expect(find.text('Offline task'), findsOneWidget);
  });

  testWidgets('surfaces a rejected optimistic write in the conflict log', (
    tester,
  ) async {
    await tester.pumpWidget(
      TaskManagerApp(transport: _DemoTransport(rejectPushes: true)),
    );

    await _addTask(tester, 'Rejected task');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Rejected task'), findsNothing);

    await tester.tap(find.byIcon(Icons.warning_amber_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Conflict / rollback log'), findsOneWidget);
    expect(find.text('Synthetic demo rejection'), findsOneWidget);
  });
}
