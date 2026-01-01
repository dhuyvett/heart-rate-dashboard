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

  /// Timestamp when the reading was received.
  final DateTime receivedAt;

  /// Creates a heart rate data instance.
  const HeartRateData({
    required this.bpm,
    required this.zone,
    required this.receivedAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HeartRateData &&
        other.bpm == bpm &&
        other.zone == zone &&
        other.receivedAt == receivedAt;
  }

  @override
  int get hashCode => Object.hash(bpm, zone, receivedAt);

  @override
  String toString() {
    return 'HeartRateData(bpm: $bpm, zone: $zone, receivedAt: $receivedAt)';
  }
}
