/// A paused interval within a workout session.
class SessionPauseInterval {
  final int? id;
  final int sessionId;
  final DateTime pauseStart;
  final DateTime pauseEnd;

  const SessionPauseInterval({
    this.id,
    required this.sessionId,
    required this.pauseStart,
    required this.pauseEnd,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'pause_start': pauseStart.millisecondsSinceEpoch,
      'pause_end': pauseEnd.millisecondsSinceEpoch,
    };
  }

  factory SessionPauseInterval.fromMap(Map<String, dynamic> map) {
    return SessionPauseInterval(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      pauseStart: DateTime.fromMillisecondsSinceEpoch(
        map['pause_start'] as int,
      ),
      pauseEnd: DateTime.fromMillisecondsSinceEpoch(map['pause_end'] as int),
    );
  }
}
