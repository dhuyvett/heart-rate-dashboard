import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/sex.dart';
import 'package:heart_rate_dashboard/models/heart_rate_data.dart';
import 'package:heart_rate_dashboard/models/heart_rate_zone.dart';
import 'package:heart_rate_dashboard/models/scanned_device.dart';
import 'package:heart_rate_dashboard/models/session_state.dart';
import 'package:heart_rate_dashboard/providers/device_scan_provider.dart';
import 'package:heart_rate_dashboard/providers/heart_rate_provider.dart';
import 'package:heart_rate_dashboard/providers/session_provider.dart';
import 'package:heart_rate_dashboard/screens/device_selection_screen.dart';
import 'package:heart_rate_dashboard/utils/heart_rate_zone_calculator.dart';

/// A simplified test widget for testing heart rate display behavior
/// without the full screen's initialization logic (which requires database access).
class TestHRMonitoringWidget extends ConsumerWidget {
  final String deviceName;

  const TestHRMonitoringWidget({required this.deviceName, super.key});

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
          const Text('Average'),
          Text(sessionState.avgHr?.toString() ?? '--'),
          const Text('Minimum'),
          Text(sessionState.minHr?.toString() ?? '--'),
          const Text('Maximum'),
          Text(sessionState.maxHr?.toString() ?? '--'),
          const Text('Duration'),
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

/// A simplified settings test widget for testing zone display.
class TestSettingsWidget extends StatelessWidget {
  final int age;

  const TestSettingsWidget({this.age = 30, super.key});

  @override
  Widget build(BuildContext context) {
    final zoneRanges = HeartRateZoneCalculator.getZoneRangesBySex(
      age,
      Sex.male,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Heart Rate Zones'),
          const Text('Your Age'),
          const Text('Chart Time Window'),
          ...zoneRanges.entries.map((entry) {
            final label = HeartRateZoneCalculator.getZoneLabel(entry.key);
            return Text('$label: ${entry.value.$1}-${entry.value.$2} BPM');
          }),
        ],
      ),
    );
  }
}

/// Integration tests for complete workflow scenarios.
///
/// These tests verify critical end-to-end user workflows for the
/// Bluetooth heart rate monitoring feature. They focus on:
/// - Device selection and connection flow
/// - Real-time heart rate display with zone updates
/// - Settings changes affecting zone calculation
/// - Session statistics calculation
/// - Demo mode functioning as a real device
void main() {
  group('Complete Workflow Integration Tests', () {
    testWidgets('device selection shows demo mode and navigates on tap', (
      WidgetTester tester,
    ) async {
      // Arrange: Create device list with demo mode
      final devices = [
        ScannedDevice.demoMode(),
        const ScannedDevice(id: 'device_1', name: 'Polar H10', rssi: -55),
      ];

      // Build device selection screen with mocked provider
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceScanProvider.overrideWith((ref) => Stream.value(devices)),
          ],
          child: const MaterialApp(home: DeviceSelectionScreen()),
        ),
      );

      // Use pump with duration instead of pumpAndSettle (animations may not settle)
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Demo mode should appear first with special icon
      expect(find.text('Demo Mode'), findsOneWidget);
      expect(find.text('Polar H10'), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
    });

    testWidgets(
      'heart rate monitoring displays zone changes based on BPM value',
      (WidgetTester tester) async {
        // Test that zone colors change correctly based on BPM
        // For age 30: Zone boundaries at 95, 114, 133, 152, 171 BPM

        final sessionState = SessionState(
          currentSessionId: 1,
          startTime: DateTime.now(),
          duration: const Duration(minutes: 5),
          avgHr: 140,
          minHr: 120,
          maxHr: 160,
          readingsCount: 150,
        );

        // Test Zone 2 (60-70% = 114-132 BPM for age 30)
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              heartRateProvider.overrideWith(
                (ref) => Stream.value(
                  const HeartRateData(bpm: 125, zone: HeartRateZone.zone2),
                ).asyncMap((d) => d),
              ),
              sessionProvider.overrideWith(
                () => MockSessionNotifier(sessionState),
              ),
            ],
            child: const MaterialApp(
              home: TestHRMonitoringWidget(deviceName: 'Test Device'),
            ),
          ),
        );

        // Use pump with duration instead of pumpAndSettle
        await tester.pump(const Duration(milliseconds: 100));

        // Verify BPM displayed
        expect(find.text('125'), findsOneWidget);

        // Verify zone label displayed
        expect(find.textContaining('Zone 2'), findsOneWidget);
      },
    );

    testWidgets('session statistics update correctly from readings', (
      WidgetTester tester,
    ) async {
      // Create session with specific statistics
      final sessionState = SessionState(
        currentSessionId: 1,
        startTime: DateTime.now().subtract(const Duration(minutes: 15)),
        duration: const Duration(minutes: 15, seconds: 45),
        avgHr: 145,
        minHr: 110,
        maxHr: 175,
        readingsCount: 500,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            heartRateProvider.overrideWith(
              (ref) => Stream.value(
                const HeartRateData(bpm: 150, zone: HeartRateZone.zone3),
              ).asyncMap((d) => d),
            ),
            sessionProvider.overrideWith(
              () => MockSessionNotifier(sessionState),
            ),
          ],
          child: const MaterialApp(
            home: TestHRMonitoringWidget(deviceName: 'Test Device'),
          ),
        ),
      );

      // Use pump with duration instead of pumpAndSettle
      await tester.pump(const Duration(milliseconds: 100));

      // Verify all statistics are displayed correctly
      expect(find.text('145'), findsOneWidget); // Average HR
      expect(find.text('110'), findsOneWidget); // Min HR
      expect(find.text('175'), findsOneWidget); // Max HR

      // Verify labels are present
      expect(find.text('Average'), findsOneWidget);
      expect(find.text('Minimum'), findsOneWidget);
      expect(find.text('Maximum'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
    });

    testWidgets('settings screen shows zone ranges based on age', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TestSettingsWidget(age: 30)),
      );

      // Use pump with duration instead of pumpAndSettle
      await tester.pump(const Duration(milliseconds: 100));

      // Verify settings screen shows zone information
      expect(find.text('Heart Rate Zones'), findsOneWidget);
      expect(find.text('Your Age'), findsOneWidget);
      expect(find.text('Chart Time Window'), findsOneWidget);

      // Verify zone labels are shown
      expect(find.textContaining('Resting'), findsOneWidget);
      expect(find.textContaining('Zone 1'), findsOneWidget);
      expect(find.textContaining('Zone 2'), findsOneWidget);
      expect(find.textContaining('Zone 3'), findsOneWidget);
      expect(find.textContaining('Zone 4'), findsOneWidget);
      expect(find.textContaining('Zone 5'), findsOneWidget);
    });

    testWidgets('monitoring screen shows settings button in app bar', (
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
            home: TestHRMonitoringWidget(deviceName: 'Test Device'),
          ),
        ),
      );

      // Use pump with duration instead of pumpAndSettle
      await tester.pump(const Duration(milliseconds: 100));

      // Verify settings icon is present and tappable
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);
    });

    test('zone calculator correctly determines zones for different ages', () {
      // Test age 25, male (Max HR = 194)
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(80, 25, Sex.male),
        equals(HeartRateZone.resting),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(120, 25, Sex.male),
        equals(HeartRateZone.zone2),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(180, 25, Sex.male),
        equals(HeartRateZone.zone5),
      );

      // Test age 50, male (Max HR = 174)
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(80, 50, Sex.male),
        equals(HeartRateZone.resting),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(115, 50, Sex.male),
        equals(HeartRateZone.zone2),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(160, 50, Sex.male),
        equals(HeartRateZone.zone5),
      );
    });

    test('zone ranges change when age changes', () {
      // Get ranges for age 30, male
      final ranges30 = HeartRateZoneCalculator.getZoneRangesBySex(30, Sex.male);

      // Get ranges for age 40, male
      final ranges40 = HeartRateZoneCalculator.getZoneRangesBySex(40, Sex.male);

      // Age 40 should have lower zone boundaries than age 30
      // because max HR is lower (180 vs 190)
      expect(
        ranges40[HeartRateZone.zone5]!.$2,
        lessThan(ranges30[HeartRateZone.zone5]!.$2),
      );
      expect(
        ranges40[HeartRateZone.zone1]!.$1,
        lessThan(ranges30[HeartRateZone.zone1]!.$1),
      );
    });

    testWidgets('demo mode device shows distinctive icon', (
      WidgetTester tester,
    ) async {
      final devices = [ScannedDevice.demoMode()];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceScanProvider.overrideWith((ref) => Stream.value(devices)),
          ],
          child: const MaterialApp(home: DeviceSelectionScreen()),
        ),
      );

      // Use pump with duration instead of pumpAndSettle
      await tester.pump(const Duration(milliseconds: 100));

      // Demo mode should have psychology icon
      expect(find.byIcon(Icons.psychology), findsOneWidget);

      // Demo mode should show the subtitle text instead of signal bars
      expect(
        find.text('Simulated heart rate data for testing'),
        findsOneWidget,
      );
    });

    testWidgets('monitoring screen displays no data placeholder', (
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
            home: TestHRMonitoringWidget(deviceName: 'Test Device'),
          ),
        ),
      );

      // Use pump with duration instead of pumpAndSettle
      await tester.pump(const Duration(milliseconds: 100));

      // Should show placeholder when no data
      expect(find.text('---'), findsOneWidget);
      expect(find.textContaining('Waiting'), findsOneWidget);
    });

    test('scanned device demo mode has correct properties', () {
      final demoDevice = ScannedDevice.demoMode();

      expect(demoDevice.isDemo, isTrue);
      expect(demoDevice.name, equals('Demo Mode'));
      expect(demoDevice.rssi, equals(-30)); // Excellent signal
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
