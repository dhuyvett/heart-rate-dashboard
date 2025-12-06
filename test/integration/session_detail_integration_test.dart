// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/app_settings.dart';
import 'package:heart_rate_dashboard/models/workout_session.dart';
import 'package:heart_rate_dashboard/providers/settings_provider.dart';
import 'package:heart_rate_dashboard/screens/session_detail_screen.dart';
import '../helpers/fake_settings_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionDetailScreen integration', () {
    testWidgets('renders with async settings provider', (tester) async {
      final preset = const AppSettings();
      final session = WorkoutSession(
        id: 1,
        deviceName: 'Test Device',
        startTime: DateTime(2025, 1, 1, 10),
        endTime: DateTime(2025, 1, 1, 11),
        avgHr: 120,
        minHr: 100,
        maxHr: 150,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => FakeSettingsNotifier(preset)),
          ],
          child: MaterialApp(home: SessionDetailScreen(session: session)),
        ),
      );

      await tester.pump(); // settle async build

      expect(find.text('Test Device'), findsOneWidget);
      expect(find.text('Test Device'), findsOneWidget);
    });
  });
}
