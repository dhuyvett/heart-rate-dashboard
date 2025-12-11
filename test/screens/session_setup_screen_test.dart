import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/screens/session_setup_screen.dart';
import 'package:flutter/material.dart'
    show ButtonStyleButton, MaterialApp, TextField;

void main() {
  group('SessionSetupScreen', () {
    testWidgets('prefills default name and disables Start when empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: SessionSetupScreen(deviceName: 'Test Device')),
      );
      await tester.pumpAndSettle();

      // Default name is populated
      expect(find.textContaining('Session -'), findsOneWidget);

      final startText = find.text('Start');
      expect(startText, findsOneWidget);
      final startButton = find.ancestor(
        of: startText,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ButtonStyleButton ||
              widget.runtimeType.toString() == 'FilledButton',
        ),
      );
      expect(startButton, findsOneWidget);
      expect((tester.widget(startButton) as dynamic).onPressed, isNotNull);

      // Clear text -> Start disabled
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(startButton, findsOneWidget);
      expect((tester.widget(startButton) as dynamic).onPressed, isNull);

      // Re-enter name -> Start enabled
      await tester.enterText(find.byType(TextField), 'Evening Ride');
      await tester.pumpAndSettle();

      expect(startButton, findsOneWidget);
      expect((tester.widget(startButton) as dynamic).onPressed, isNotNull);
    });
  });
}
