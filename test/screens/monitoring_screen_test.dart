import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/models/heart_rate_data.dart';
import 'package:workout_tracker/models/heart_rate_zone.dart';
import 'package:workout_tracker/models/session_state.dart';
import 'package:workout_tracker/providers/heart_rate_provider.dart';
import 'package:workout_tracker/providers/session_provider.dart';
import 'package:workout_tracker/screens/heart_rate_monitoring_screen.dart';

void main() {
  group('HeartRateMonitoringScreen', () {
    testWidgets('displays BPM value when heart rate data is available', (
      WidgetTester tester,
    ) async {
      // Mock heart rate data
      final hrData = const HeartRateData(bpm: 145, zone: HeartRateZone.zone3);

      // Mock session state
      final sessionState = SessionState(
        currentSessionId: 1,
        startTime: DateTime.now(),
        duration: const Duration(minutes: 5),
        avgHr: 140,
        minHr: 120,
        maxHr: 160,
        readingsCount: 150,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heartRateProvider.overrideWith(
              (ref) => Stream.value(hrData).asyncMap((d) => d),
            ),
            sessionProvider.overrideWith(
              () => MockSessionNotifier(sessionState),
            ),
          ],
          child: const MaterialApp(
            home: HeartRateMonitoringScreen(deviceName: 'Test Device'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify BPM is displayed
      expect(find.text('145'), findsOneWidget);

      // Verify zone label is displayed
      expect(find.textContaining('Zone 3'), findsOneWidget);
    });

    testWidgets('displays session statistics', (WidgetTester tester) async {
      // Mock session with statistics
      final sessionState = SessionState(
        currentSessionId: 1,
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        duration: const Duration(minutes: 10, seconds: 30),
        avgHr: 142,
        minHr: 120,
        maxHr: 165,
        readingsCount: 300,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heartRateProvider.overrideWith(
              (ref) => Stream.value(
                const HeartRateData(bpm: 145, zone: HeartRateZone.zone3),
              ).asyncMap((d) => d),
            ),
            sessionProvider.overrideWith(
              () => MockSessionNotifier(sessionState),
            ),
          ],
          child: const MaterialApp(
            home: HeartRateMonitoringScreen(deviceName: 'Test Device'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify statistics are displayed
      expect(find.text('142'), findsOneWidget); // Average HR
      expect(find.text('120'), findsOneWidget); // Min HR
      expect(find.text('165'), findsOneWidget); // Max HR
    });

    testWidgets('shows --- when no heart rate data available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heartRateProvider.overrideWith((ref) => const Stream.empty()),
            sessionProvider.overrideWith(
              () => MockSessionNotifier(SessionState.inactive()),
            ),
          ],
          child: const MaterialApp(
            home: HeartRateMonitoringScreen(deviceName: 'Test Device'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify placeholder is shown when no data
      expect(find.text('---'), findsOneWidget);
    });

    testWidgets('displays device name in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heartRateProvider.overrideWith((ref) => const Stream.empty()),
            sessionProvider.overrideWith(
              () => MockSessionNotifier(SessionState.inactive()),
            ),
          ],
          child: const MaterialApp(
            home: HeartRateMonitoringScreen(deviceName: 'My HR Monitor'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify device name is shown in app bar
      expect(find.text('My HR Monitor'), findsOneWidget);
    });

    testWidgets('has settings button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heartRateProvider.overrideWith((ref) => const Stream.empty()),
            sessionProvider.overrideWith(
              () => MockSessionNotifier(SessionState.inactive()),
            ),
          ],
          child: const MaterialApp(
            home: HeartRateMonitoringScreen(deviceName: 'Test Device'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify settings button is present
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}

/// Mock session notifier for testing.
class MockSessionNotifier extends SessionNotifier {
  final SessionState _state;

  MockSessionNotifier(this._state);

  @override
  SessionState build() => _state;
}
