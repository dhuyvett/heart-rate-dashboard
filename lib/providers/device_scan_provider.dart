import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scanned_device.dart';
import '../services/bluetooth_service.dart';
import '../utils/app_logger.dart';

/// Provider for Bluetooth device scanning.
///
/// Streams a list of discovered devices that advertise the Heart Rate Service.
/// The demo mode device is always included in the list, even if scanning fails.
/// The demo device is emitted immediately to avoid loading spinners.
final deviceScanProvider = StreamProvider<List<ScannedDevice>>((ref) async* {
  final logger = AppLogger.getLogger('DeviceScanProvider');
  final bluetoothService = BluetoothService.instance;

  // Always include demo mode device as first item
  final demoDevice = ScannedDevice.demoMode();

  // Emit demo device immediately so UI doesn't show loading spinner
  yield [demoDevice];

  try {
    // Start scanning for real devices
    await for (final devices in bluetoothService.scanForDevices()) {
      // Convert Bluetooth devices to ScannedDevice models
      final scannedDevices = devices.map((device) {
        return ScannedDevice(
          id: device.remoteId.str,
          name: device.platformName.isNotEmpty
              ? device.platformName
              : 'Unknown Device',
          rssi: 0, // RSSI will be updated from scan results if available
          isDemo: false,
        );
      }).toList();

      // Prepend demo device to the list
      yield [demoDevice, ...scannedDevices];
    }
  } on StateError catch (e, stackTrace) {
    // If Bluetooth is unavailable or off, log the error
    // Demo device is already shown, so just log and continue
    logger.w('Bluetooth scanning error', error: e, stackTrace: stackTrace);
  } catch (e, stackTrace) {
    // For other errors, log but don't crash
    // Demo device is already shown
    logger.e(
      'Unexpected error during device scanning',
      error: e,
      stackTrace: stackTrace,
    );
  }
});
