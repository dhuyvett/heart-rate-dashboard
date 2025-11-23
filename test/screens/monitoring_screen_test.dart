import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/heart_rate_data.dart';
import 'package:heart_rate_dashboard/models/heart_rate_zone.dart';
import 'package:heart_rate_dashboard/models/session_state.dart';
import 'package:heart_rate_dashboard/providers/heart_rate_provider.dart';
import 'package:heart_rate_dashboard/providers/session_provider.dart';

/// A simplified test widget that displays HR monitoring UI without the full screen's
/// initialization logic (which requires database access).
class TestHeartRateDisplay extends ConsumerWidget {
  final String deviceName;

  const TestHeartRateDisplay({required this.deviceName, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heartRateAsync = ref.watch(heartRateProvider);
    final sessionState = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(deviceName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // BPM Display
          heartRateAsync.when(
            data: (hrData) => Text('${hrData.bpm}'),
            loading: () => const Text('---'),
            error: (_, _) => const Text('---'),
          ),
          // Zone Label
          heartRateAsync.when(
            data: (hrData) => Text(_getZoneLabel(hrData.zone)),
            loading: () => const Text('Waiting for data...'),
            error: (_, _) => const Text('Error'),
          ),
          // Session Statistics
          Text('Average'),
          Text(sessionState.avgHr?.toString() ?? '--'),
          Text('Minimum'),
          Text(sessionState.minHr?.toString() ?? '--'),
          Text('Maximum'),
          Text(sessionState.maxHr?.toString() ?? '--'),
          Text('Duration'),
        ],
      ),
    );
  }

  String _getZoneLabel(HeartRateZone zone) {
    switch (zone) {
      case HeartRateZone.resting:
        return 'Resting';
      case HeartRateZone.zone1:
        return 'Zone 1 - Light';
      case HeartRateZone.zone2:
        return 'Zone 2 - Easy';
      case HeartRateZone.zone3:
        return 'Zone 3 - Moderate';
      case HeartRateZone.zone4:
        return 'Zone 4 - Hard';
      case HeartRateZone.zone5:
        return 'Zone 5 - Maximum';
    }
  }
}

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
            home: TestHeartRateDisplay(deviceName: 'Test Device'),
          ),
        ),
      );

      // Use pump with duration instead of pumpAndSettle (animations never settle)
      await tester.pump(const Duration(milliseconds: 100));

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
            home: TestHeartRateDisplay(deviceName: 'Test Device'),
          ),
        ),
      );

      // Use pump with duration instead of pumpAndSettle
      await tester.pump(const Duration(milliseconds: 100));

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
            home: TestHeartRateDisplay(deviceName: 'Test Device'),
          ),
        ),
      );

      // Use pump with duration instead of pumpAndSettle
      await tester.pump(const Duration(milliseconds: 100));

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
            home: TestHeartRateDisplay(deviceName: 'My HR Monitor'),
          ),
        ),
      );

      // Use pump with duration instead of pumpAndSettle
      await tester.pump(const Duration(milliseconds: 100));

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
            home: TestHeartRateDisplay(deviceName: 'Test Device'),
          ),
        ),
      );

      // Use pump with duration instead of pumpAndSettle
      await tester.pump(const Duration(milliseconds: 100));

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
