import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/models/scanned_device.dart';
import 'package:workout_tracker/providers/device_scan_provider.dart';
import 'package:workout_tracker/screens/device_selection_screen.dart';

void main() {
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

      // Wait for the stream to emit
      await tester.pumpAndSettle();

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

      await tester.pumpAndSettle();

      // Should show demo mode
      expect(find.text('Demo Mode'), findsOneWidget);

      // Should show message about no real devices
      expect(
        find.text(
          'No heart rate monitors found. Make sure your device is '
          'turned on and in range.',
        ),
        findsOneWidget,
      );
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

      await tester.pumpAndSettle();

      // Verify the scan button is present
      expect(find.text('Scan for Devices'), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_searching), findsOneWidget);
    });
  });
}
