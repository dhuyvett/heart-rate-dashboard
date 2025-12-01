// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/app_settings.dart';
import 'package:heart_rate_dashboard/models/max_hr_calculation_method.dart';
import 'package:heart_rate_dashboard/providers/settings_provider.dart';
import 'package:heart_rate_dashboard/screens/settings_screen.dart';
import 'package:heart_rate_dashboard/utils/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/fake_settings_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen', () {
    testWidgets('shows heart rate zones and disables age for custom max HR', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initial = const AppSettings(
        age: 32,
        maxHRCalculationMethod: MaxHRCalculationMethod.custom,
        customMaxHR: 190,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => FakeSettingsNotifier(initial)),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      await tester.dragUntilVisible(
        find.text('Heart Rate Zones'),
        find.byType(ListView),
        const Offset(0, -400),
      );

      expect(find.textContaining('190 BPM'), findsWidgets);
      expect(find.text('Heart Rate Zones'), findsOneWidget);

      final ageField = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'Age (years)' &&
            w.enabled == false,
      );
      expect(ageField, findsOneWidget);
      expect(find.text('Custom Max HR (BPM)'), findsOneWidget);
    });

    testWidgets('validates retention input and updates chart window', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeNotifier = FakeSettingsNotifier(
        const AppSettings(
          age: defaultAge,
          chartWindowSeconds: 30,
          sessionRetentionDays: 30,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsProvider.overrideWith(() => fakeNotifier)],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Tap chart window chip to update
      await tester.tap(find.text('45s'));
      await tester.pump();
      expect(fakeNotifier.lastChartWindow, 45);

      // Enter invalid retention to surface error
      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.labelText == 'Session Retention (days)',
        ),
        '0',
      );
      await tester.pump();
      expect(find.text('Must be between 1 and 3650 days'), findsOneWidget);

      // Enter valid retention to clear error and trigger update
      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.labelText == 'Session Retention (days)',
        ),
        '90',
      );
      await tester.pump();
      expect(find.text('Must be between 1 and 3650 days'), findsNothing);
      expect(fakeNotifier.lastRetentionDays, 90);
    });
  });
}
