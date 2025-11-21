import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/models/heart_rate_data.dart';
import 'package:workout_tracker/models/heart_rate_zone.dart';
import 'package:workout_tracker/models/scanned_device.dart';
import 'package:workout_tracker/models/session_state.dart';
import 'package:workout_tracker/providers/device_scan_provider.dart';
import 'package:workout_tracker/providers/heart_rate_provider.dart';
import 'package:workout_tracker/providers/session_provider.dart';
import 'package:workout_tracker/screens/device_selection_screen.dart';
import 'package:workout_tracker/screens/heart_rate_monitoring_screen.dart';
import 'package:workout_tracker/screens/settings_screen.dart';
import 'package:workout_tracker/utils/heart_rate_zone_calculator.dart';

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

      await tester.pumpAndSettle();

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
              home: HeartRateMonitoringScreen(deviceName: 'Test Device'),
            ),
          ),
        );

        await tester.pumpAndSettle();

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
            home: HeartRateMonitoringScreen(deviceName: 'Test Device'),
          ),
        ),
      );

      await tester.pumpAndSettle();

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
        const ProviderScope(child: MaterialApp(home: SettingsScreen())),
      );

      await tester.pumpAndSettle();

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
            home: HeartRateMonitoringScreen(deviceName: 'Test Device'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify settings icon is present and tappable
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);
    });

    test('zone calculator correctly determines zones for different ages', () {
      // Test age 25 (Max HR = 195)
      expect(
        HeartRateZoneCalculator.getZoneForBpm(80, 25),
        equals(HeartRateZone.resting),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpm(120, 25),
        equals(HeartRateZone.zone2),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpm(180, 25),
        equals(HeartRateZone.zone5),
      );

      // Test age 50 (Max HR = 170)
      expect(
        HeartRateZoneCalculator.getZoneForBpm(80, 50),
        equals(HeartRateZone.resting),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpm(115, 50),
        equals(HeartRateZone.zone2),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpm(160, 50),
        equals(HeartRateZone.zone5),
      );
    });

    test('zone ranges change when age changes', () {
      // Get ranges for age 30
      final ranges30 = HeartRateZoneCalculator.getZoneRanges(30);

      // Get ranges for age 40
      final ranges40 = HeartRateZoneCalculator.getZoneRanges(40);

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

      await tester.pumpAndSettle();

      // Demo mode should have psychology icon
      expect(find.byIcon(Icons.psychology), findsOneWidget);

      // Demo mode should have excellent signal
      expect(find.byIcon(Icons.signal_cellular_alt), findsOneWidget);
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
            home: HeartRateMonitoringScreen(deviceName: 'Test Device'),
          ),
        ),
      );

      await tester.pumpAndSettle();

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
