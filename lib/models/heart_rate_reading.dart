/// Represents a single heart rate reading from a connected device.
///
/// Heart rate readings are captured every 1-2 seconds during an active workout
/// session and stored in the local encrypted database. Each reading is associated
/// with a specific workout session via the [sessionId].
class HeartRateReading {
  /// Unique identifier for this reading in the database.
  /// Null for new readings before they're inserted.
  final int? id;

  /// The ID of the workout session this reading belongs to.
  /// Foreign key reference to the workout_sessions table.
  final int sessionId;

  /// The timestamp when this heart rate reading was captured.
  /// Stored as Unix timestamp (milliseconds since epoch) in database.
  final DateTime timestamp;

  /// Heart rate in beats per minute (BPM).
  /// Valid range: 30-250 BPM (enforced by validation).
  final int bpm;

  /// Creates a heart rate reading instance.
  ///
  /// The [bpm] value must be within the valid physiological range of 30-250.
  /// Throws [ArgumentError] if validation fails.
  HeartRateReading({
    this.id,
    required this.sessionId,
    required this.timestamp,
    required this.bpm,
  }) {
    _validate();
  }

  /// Validates the heart rate reading data.
  ///
  /// Ensures BPM is within the physiologically valid range.
  /// Throws [ArgumentError] if validation fails.
  void _validate() {
    if (bpm < 30 || bpm > 250) {
      throw ArgumentError(
        'Heart rate must be between 30 and 250 BPM, got $bpm',
      );
    }
  }

  /// Converts this reading to a map for database storage.
  ///
  /// The timestamp is converted to Unix timestamp (milliseconds since epoch)
  /// for efficient storage and querying.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'bpm': bpm,
    };
  }

  /// Creates a reading instance from a database map.
  ///
  /// Reconstructs the DateTime from the stored Unix timestamp.
  factory HeartRateReading.fromMap(Map<String, dynamic> map) {
    return HeartRateReading(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      bpm: map['bpm'] as int,
    );
  }

  @override
  String toString() {
    return 'HeartRateReading(id: $id, sessionId: $sessionId, '
        'timestamp: $timestamp, bpm: $bpm)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HeartRateReading &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.timestamp == timestamp &&
        other.bpm == bpm;
  }

  @override
  int get hashCode {
    return Object.hash(id, sessionId, timestamp, bpm);
  }
}
