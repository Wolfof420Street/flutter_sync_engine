import 'package:conflict_playground/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('conflict playground renders its two-device controls',
      (tester) async {
    final controller = ConflictPlaygroundController();
    await tester.pumpWidget(ConflictPlaygroundApp(controller: controller));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('SyncForge Conflict Playground'), findsOneWidget);
    await controller.dispose();
  });
}
