// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/screens/permission_explanation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PermissionExplanationScreen', () {
    testWidgets('displays key permission messaging and buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: PermissionExplanationScreen()),
      );

      expect(find.textContaining('Bluetooth'), findsWidgets);
      expect(find.textContaining('Grant Permission'), findsOneWidget);
    });
  });
}
