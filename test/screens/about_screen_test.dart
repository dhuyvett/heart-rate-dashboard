// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/screens/about_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AboutScreen', () {
    testWidgets('shows app name, privacy copy, and back navigation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

      expect(find.text('Heart Rate Dashboard'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
    });
  });
}
