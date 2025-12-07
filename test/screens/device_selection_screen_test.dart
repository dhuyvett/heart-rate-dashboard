// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/scanned_device.dart';
import 'package:heart_rate_dashboard/providers/device_scan_provider.dart';
import 'package:heart_rate_dashboard/screens/device_selection_screen.dart';
import 'package:heart_rate_dashboard/utils/error_messages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceSelectionScreen', () {
    testWidgets('displays demo mode device first in list', (
      WidgetTester tester,
    ) async {
      // Create a list of devices with demo mode first
      final devices = [
        ScannedDevice.demoMode(),
        const ScannedDevice(
          id: 'real_device_1',
          name: 'Heart Monitor',
          rssi: -60,
        ),
      ];

      // Build the widget with mocked provider
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

      // Verify demo mode device is displayed first
      expect(find.text('Demo Mode'), findsOneWidget);
      expect(find.text('Heart Monitor'), findsOneWidget);

      // Verify demo mode has special indicator
      expect(find.byIcon(Icons.psychology), findsOneWidget);
    });

    testWidgets('shows no devices found message when list is empty', (
      WidgetTester tester,
    ) async {
      // Create an empty list with only demo mode
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

      // Should show demo mode
      expect(find.text('Demo Mode'), findsOneWidget);

      // Should show message about no real devices (use exact constant)
      expect(find.text(errorNoDevicesFound), findsOneWidget);
    });

    testWidgets('displays scan for devices button', (
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

      // Verify the scan button is present
      expect(find.text('Scan for Devices'), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_searching), findsOneWidget);
    });

    testWidgets('scan button triggers a fresh device scan', (
      WidgetTester tester,
    ) async {
      var scanStarts = 0;

      Stream<List<ScannedDevice>> buildStream() {
        scanStarts++;
        return Stream.value([ScannedDevice.demoMode()]);
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [deviceScanProvider.overrideWith((ref) => buildStream())],
          child: const MaterialApp(home: DeviceSelectionScreen()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(scanStarts, 1);

      await tester.tap(find.text('Scan for Devices'));
      await tester.pump(const Duration(seconds: 6));

      expect(scanStarts, 2);
    });
  });
}
