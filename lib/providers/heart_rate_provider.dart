import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/heart_rate_data.dart';
import '../services/bluetooth_service.dart';
import '../utils/heart_rate_zone_calculator.dart';
import 'settings_provider.dart';

/// Provider for real-time heart rate data with zone calculation.
///
/// Subscribes to the Bluetooth service heart rate stream and transforms
/// each BPM value to include the calculated heart rate zone based on
/// the current age setting.
///
/// Uses autoDispose to ensure the stream is recreated when navigating
/// away and back to the monitoring screen, which is necessary for
/// proper reconnection to demo mode or a new device.
final heartRateProvider = StreamProvider.autoDispose<HeartRateData>((
  ref,
) async* {
  final bluetoothService = BluetoothService.instance;

  // Watch settings for zone calculation
  final settingsAsync = ref.watch(settingsProvider);
  final settings = settingsAsync.asData?.value;
  if (settings == null) {
    if (settingsAsync.hasError) {
      throw settingsAsync.error!;
    }
    return;
  }

  // Subscribe to heart rate stream
  await for (final bpm in bluetoothService.subscribeToHeartRate()) {
    // Calculate zone based on current settings
    final zone = HeartRateZoneCalculator.getZoneForBpm(bpm, settings);

    // Emit heart rate data with zone
    yield HeartRateData(bpm: bpm, zone: zone);
  }
});
