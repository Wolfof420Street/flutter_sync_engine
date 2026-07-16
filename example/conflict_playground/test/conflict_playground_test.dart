import 'package:conflict_playground/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('real engines converge concurrent field edits deterministically',
      () async {
    final controller = ConflictPlaygroundController();
    addTearDown(controller.dispose);

    await controller.initialize();
    await controller.makeOfflineEdits();
    expect(controller.deviceATask!.title, 'Buy milk');
    expect(controller.deviceBTask!.title, 'Buy eggs');

    await controller.syncDevices();

    expect(controller.deviceATask!.title, 'Buy eggs');
    expect(controller.deviceBTask!.title, 'Buy eggs');
    expect(controller.deviceATask!.details, 'Oat milk is fine');
    expect(controller.deviceBTask!.details, 'Oat milk is fine');
    expect(controller.history, isNotEmpty);
  }, timeout: const Timeout(Duration(seconds: 20)));
}
