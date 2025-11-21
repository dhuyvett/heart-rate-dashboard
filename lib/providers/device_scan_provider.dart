import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scanned_device.dart';
import '../services/bluetooth_service.dart';

/// Provider for Bluetooth device scanning.
///
/// Streams a list of discovered devices that advertise the Heart Rate Service.
/// The demo mode device is always included as the first item in the list.
final deviceScanProvider = StreamProvider<List<ScannedDevice>>((ref) async* {
  final bluetoothService = BluetoothService.instance;

  // Always include demo mode device as first item
  final demoDevice = ScannedDevice.demoMode();

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
});
