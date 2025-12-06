// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/app_settings.dart';
import 'package:heart_rate_dashboard/models/heart_rate_data.dart';
import 'package:heart_rate_dashboard/models/heart_rate_zone.dart';
import 'package:heart_rate_dashboard/models/session_state.dart';
import 'package:heart_rate_dashboard/providers/heart_rate_provider.dart';
import 'package:heart_rate_dashboard/providers/settings_provider.dart';
import 'package:heart_rate_dashboard/providers/session_provider.dart';
import 'package:heart_rate_dashboard/screens/heart_rate_monitoring_screen.dart';

import '../integration/complete_workflow_test.dart' show MockSessionNotifier;
import '../helpers/fake_settings_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HeartRateMonitoringScreen', () {
    testWidgets('shows loading/error states from providers', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heartRateProvider.overrideWith(
              (ref) => Stream<HeartRateData>.error('failed'),
            ),
            settingsProvider.overrideWith(
              () => FakeSettingsNotifier(const AppSettings()),
            ),
            sessionProvider.overrideWith(
              () => MockSessionNotifier(SessionState.inactive()),
            ),
          ],
          child: const MaterialApp(
            home: HeartRateMonitoringScreen(deviceName: 'Polar'),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.textContaining('---'), findsWidgets);
    });

    testWidgets('renders live BPM and zone label when data arrives', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heartRateProvider.overrideWith(
              (ref) => Stream.value(
                const HeartRateData(bpm: 150, zone: HeartRateZone.zone4),
              ),
            ),
            settingsProvider.overrideWith(
              () => FakeSettingsNotifier(const AppSettings()),
            ),
            sessionProvider.overrideWith(
              () => MockSessionNotifier(
                SessionState(
                  currentSessionId: 1,
                  startTime: DateTime.now(),
                  duration: const Duration(minutes: 5),
                  avgHr: 140,
                  minHr: 120,
                  maxHr: 160,
                  readingsCount: 100,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: HeartRateMonitoringScreen(deviceName: 'Polar'),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('150'), findsOneWidget);
      expect(find.textContaining('Zone 4'), findsOneWidget);
    });
  });
}
