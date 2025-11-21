import 'heart_rate_zone.dart';

/// Represents a heart rate reading with calculated zone information.
///
/// This combines the raw BPM value with the calculated heart rate zone
/// based on the user's age setting.
class HeartRateData {
  /// Heart rate in beats per minute.
  final int bpm;

  /// The calculated heart rate zone for this BPM value.
  final HeartRateZone zone;

  /// Creates a heart rate data instance.
  const HeartRateData({required this.bpm, required this.zone});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HeartRateData && other.bpm == bpm && other.zone == zone;
  }

  @override
  int get hashCode => Object.hash(bpm, zone);

  @override
  String toString() {
    return 'HeartRateData(bpm: $bpm, zone: $zone)';
  }
}
