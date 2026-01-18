/// Represents a workout session with heart rate monitoring.
///
/// A session begins when a device connects and ends when it disconnects.
/// Session statistics (average, min, max HR) are calculated and stored
/// when the session ends.
class WorkoutSession {
  /// Unique identifier for this session in the database.
  /// Null for new sessions before they're inserted.
  final int? id;

  /// The timestamp when this session started (device connected).
  /// Stored as Unix timestamp (milliseconds since epoch) in database.
  final DateTime startTime;

  /// The timestamp when this session ended (device disconnected).
  /// Null if the session is still active.
  /// Stored as Unix timestamp (milliseconds since epoch) in database.
  final DateTime? endTime;

  /// The name of the Bluetooth device used for this session.
  /// Can be "Demo Mode" for simulated sessions.
  final String deviceName;

  /// The user-provided or default session name.
  final String name;

  /// Average heart rate for the entire session in BPM.
  /// Calculated and stored when the session ends.
  /// Null for active sessions.
  final int? avgHr;

  /// Minimum heart rate recorded during the session in BPM.
  /// Calculated and stored when the session ends.
  /// Null for active sessions.
  final int? minHr;

  /// Maximum heart rate recorded during the session in BPM.
  /// Calculated and stored when the session ends.
  /// Null for active sessions.
  final int? maxHr;

  /// Total distance traveled during the session in meters.
  final double? distanceMeters;

  /// Whether speed/distance tracking was enabled for this session.
  final bool trackSpeedDistance;

  /// Creates a workout session instance.
  WorkoutSession({
    this.id,
    required this.startTime,
    this.endTime,
    required this.deviceName,
    required this.name,
    this.avgHr,
    this.minHr,
    this.maxHr,
    this.distanceMeters,
    this.trackSpeedDistance = false,
  });

  /// Calculates the duration of this session.
  ///
  /// If the session is still active (no end time), returns the duration
  /// from start time to now. Otherwise, returns the duration from start
  /// to end time.
  Duration getDuration() {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Checks if this session is currently active (not ended).
  bool get isActive => endTime == null;

  /// Converts this session to a map for database storage.
  ///
  /// Timestamps are converted to Unix timestamps (milliseconds since epoch)
  /// for efficient storage and querying.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'device_name': deviceName,
      'name': name,
      'avg_hr': avgHr,
      'min_hr': minHr,
      'max_hr': maxHr,
      'distance_meters': distanceMeters,
      'track_speed_distance': trackSpeedDistance ? 1 : 0,
    };
  }

  /// Creates a session instance from a database map.
  ///
  /// Reconstructs DateTimes from the stored Unix timestamps.
  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    final startTime = DateTime.fromMillisecondsSinceEpoch(
      map['start_time'] as int,
    );
    return WorkoutSession(
      id: map['id'] as int?,
      startTime: startTime,
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      deviceName: map['device_name'] as String,
      name: (map['name'] as String?) ?? _buildFallbackName(startTime),
      avgHr: map['avg_hr'] as int?,
      minHr: map['min_hr'] as int?,
      maxHr: map['max_hr'] as int?,
      distanceMeters: (map['distance_meters'] as num?)?.toDouble(),
      trackSpeedDistance: (map['track_speed_distance'] as int? ?? 0) == 1,
    );
  }

  /// Creates a copy of this session with updated fields.
  ///
  /// Used to update session statistics when ending a session.
  WorkoutSession copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    String? deviceName,
    String? name,
    int? avgHr,
    int? minHr,
    int? maxHr,
    double? distanceMeters,
    bool? trackSpeedDistance,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      deviceName: deviceName ?? this.deviceName,
      name: name ?? this.name,
      avgHr: avgHr ?? this.avgHr,
      minHr: minHr ?? this.minHr,
      maxHr: maxHr ?? this.maxHr,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      trackSpeedDistance: trackSpeedDistance ?? this.trackSpeedDistance,
    );
  }

  @override
  String toString() {
    return 'WorkoutSession(id: $id, startTime: $startTime, endTime: $endTime, '
        'deviceName: $deviceName, name: $name, avgHr: $avgHr, '
        'minHr: $minHr, maxHr: $maxHr, distanceMeters: $distanceMeters, '
        'trackSpeedDistance: $trackSpeedDistance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkoutSession &&
        other.id == id &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.deviceName == deviceName &&
        other.name == name &&
        other.avgHr == avgHr &&
        other.minHr == minHr &&
        other.maxHr == maxHr &&
        other.distanceMeters == distanceMeters &&
        other.trackSpeedDistance == trackSpeedDistance;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      startTime,
      endTime,
      deviceName,
      name,
      avgHr,
      minHr,
      maxHr,
      distanceMeters,
      trackSpeedDistance,
    );
  }

  static String _buildFallbackName(DateTime startTime) {
    return 'Session - '
        '${startTime.year.toString().padLeft(4, '0')}-'
        '${startTime.month.toString().padLeft(2, '0')}-'
        '${startTime.day.toString().padLeft(2, '0')} '
        '${startTime.hour.toString().padLeft(2, '0')}:'
        '${startTime.minute.toString().padLeft(2, '0')}';
  }
}
