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
final heartRateProvider = StreamProvider<HeartRateData>((ref) async* {
  final bluetoothService = BluetoothService.instance;

  // Watch settings to get current age for zone calculation
  final settings = ref.watch(settingsProvider);

  // Subscribe to heart rate stream
  await for (final bpm in bluetoothService.subscribeToHeartRate()) {
    // Calculate zone based on current age
    final zone = HeartRateZoneCalculator.getZoneForBpm(bpm, settings.age);

    // Emit heart rate data with zone
    yield HeartRateData(bpm: bpm, zone: zone);
  }
});
