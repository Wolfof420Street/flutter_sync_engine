import 'package:conflict_playground/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('conflict playground renders its two-device controls', (
    tester,
  ) async {
    final controller = ConflictPlaygroundController();
    await controller.initialize();
    await tester.pumpWidget(ConflictPlaygroundApp(controller: controller));
    await tester.pump();
    expect(find.text('SyncForge Conflict Playground'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.runAsync(controller.dispose);
  });
}
