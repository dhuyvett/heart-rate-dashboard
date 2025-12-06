// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/app_settings.dart';
import 'package:heart_rate_dashboard/models/max_hr_calculation_method.dart';
import 'package:heart_rate_dashboard/models/sex.dart';
import 'package:heart_rate_dashboard/providers/settings_provider.dart';
import 'package:heart_rate_dashboard/screens/settings_screen.dart';
import '../helpers/fake_settings_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen integration', () {
    testWidgets('renders loaded settings without spinner', (tester) async {
      final preset = const AppSettings(
        age: 42,
        sex: Sex.female,
        maxHRCalculationMethod: MaxHRCalculationMethod.tanakaFormula,
        chartWindowSeconds: 45,
        keepScreenAwake: true,
        darkMode: true,
        sessionRetentionDays: 90,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => FakeSettingsNotifier(preset)),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      await tester.pump(); // settle async build

      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
