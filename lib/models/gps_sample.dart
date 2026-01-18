/// Represents a GPS sample captured during a workout session.
class GpsSample {
  /// Unique identifier for this sample in the database.
  /// Null for new samples before they're inserted.
  final int? id;

  /// The ID of the workout session this sample belongs to.
  final int sessionId;

  /// Timestamp when the sample was captured.
  final DateTime timestamp;

  /// Speed in meters per second.
  final double speedMps;

  /// Altitude in meters above sea level, if available.
  final double? altitudeMeters;

  GpsSample({
    this.id,
    required this.sessionId,
    required this.timestamp,
    required this.speedMps,
    this.altitudeMeters,
  });

  /// Converts this sample to a map for database storage.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'speed_mps': speedMps,
      'altitude_meters': altitudeMeters,
    };
  }

  /// Creates a sample instance from a database map.
  factory GpsSample.fromMap(Map<String, Object?> map) {
    return GpsSample(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      speedMps: (map['speed_mps'] as num).toDouble(),
      altitudeMeters: (map['altitude_meters'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'GpsSample(id: $id, sessionId: $sessionId, '
        'timestamp: $timestamp, speedMps: $speedMps, '
        'altitudeMeters: $altitudeMeters)';
  }
}
