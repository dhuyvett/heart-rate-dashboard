// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/screens/max_hr_info_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MaxHRInfoScreen', () {
    testWidgets('renders calculation methods and closes via back button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: MaxHRInfoScreen()));

      expect(find.textContaining('Max Heart Rate'), findsWidgets);
      await tester.dragUntilVisible(
        find.text('HUNT Formula'),
        find.byType(ListView),
        const Offset(0, -600),
      );
      expect(find.text('HUNT Formula'), findsOneWidget);
      expect(find.text('Tanaka Formula'), findsOneWidget);
      expect(find.text('Fox Formula'), findsOneWidget);
    });
  });
}
