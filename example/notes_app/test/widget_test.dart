import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/main.dart';
import 'package:notes_app/note_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('external consumer launches with public sync API', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = NoteStorage(await SharedPreferences.getInstance());
    await storage.initialize();
    await tester.pumpWidget(NotesApp(storage: storage));
    expect(find.text('Offline notes'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('New note'), findsOneWidget);
  });
}
