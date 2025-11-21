/// Represents the current state of an active workout session.
///
/// This state is maintained in memory during a session and includes
/// real-time statistics that are calculated from accumulated readings.
class SessionState {
  /// The database ID of the current session.
  /// Null if no session is active.
  final int? currentSessionId;

  /// The timestamp when the session started.
  /// Null if no session is active.
  final DateTime? startTime;

  /// The current duration of the session.
  /// Calculated from start time to now.
  final Duration duration;

  /// Average heart rate for the session in BPM.
  /// Null if no readings have been recorded yet.
  final int? avgHr;

  /// Minimum heart rate recorded in the session in BPM.
  /// Null if no readings have been recorded yet.
  final int? minHr;

  /// Maximum heart rate recorded in the session in BPM.
  /// Null if no readings have been recorded yet.
  final int? maxHr;

  /// Total number of heart rate readings recorded.
  final int readingsCount;

  /// Creates a session state instance.
  const SessionState({
    this.currentSessionId,
    this.startTime,
    this.duration = Duration.zero,
    this.avgHr,
    this.minHr,
    this.maxHr,
    this.readingsCount = 0,
  });

  /// Factory constructor for creating an inactive session state.
  factory SessionState.inactive() {
    return const SessionState();
  }

  /// Whether a session is currently active.
  bool get isActive => currentSessionId != null;

  /// Creates a copy of this state with updated fields.
  SessionState copyWith({
    int? currentSessionId,
    DateTime? startTime,
    Duration? duration,
    int? avgHr,
    int? minHr,
    int? maxHr,
    int? readingsCount,
  }) {
    return SessionState(
      currentSessionId: currentSessionId ?? this.currentSessionId,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      avgHr: avgHr ?? this.avgHr,
      minHr: minHr ?? this.minHr,
      maxHr: maxHr ?? this.maxHr,
      readingsCount: readingsCount ?? this.readingsCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SessionState &&
        other.currentSessionId == currentSessionId &&
        other.startTime == startTime &&
        other.duration == duration &&
        other.avgHr == avgHr &&
        other.minHr == minHr &&
        other.maxHr == maxHr &&
        other.readingsCount == readingsCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentSessionId,
      startTime,
      duration,
      avgHr,
      minHr,
      maxHr,
      readingsCount,
    );
  }

  @override
  String toString() {
    return 'SessionState(currentSessionId: $currentSessionId, startTime: $startTime, '
        'duration: $duration, avgHr: $avgHr, minHr: $minHr, maxHr: $maxHr, '
        'readingsCount: $readingsCount)';
  }
}
