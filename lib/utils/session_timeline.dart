import '../models/session_pause_interval.dart';

/// Returns active elapsed seconds from [sessionStart] to [timestamp],
/// excluding overlap with [pauseIntervals].
double activeElapsedSecondsAt({
  required DateTime sessionStart,
  required DateTime timestamp,
  required List<SessionPauseInterval> pauseIntervals,
}) {
  if (!timestamp.isAfter(sessionStart)) {
    return 0;
  }

  final totalElapsed = timestamp.difference(sessionStart);
  final paused = pausedDurationInRange(
    rangeStart: sessionStart,
    rangeEnd: timestamp,
    pauseIntervals: pauseIntervals,
  );
  final active = totalElapsed - paused;
  return active.isNegative ? 0 : active.inMilliseconds / 1000.0;
}

/// Returns active duration between [rangeStart] and [rangeEnd], excluding
/// overlap with [pauseIntervals].
Duration activeDurationInRange({
  required DateTime rangeStart,
  required DateTime rangeEnd,
  required List<SessionPauseInterval> pauseIntervals,
}) {
  if (!rangeEnd.isAfter(rangeStart)) {
    return Duration.zero;
  }
  final elapsed = rangeEnd.difference(rangeStart);
  final paused = pausedDurationInRange(
    rangeStart: rangeStart,
    rangeEnd: rangeEnd,
    pauseIntervals: pauseIntervals,
  );
  final active = elapsed - paused;
  return active.isNegative ? Duration.zero : active;
}

/// Returns total paused duration overlapping [rangeStart, rangeEnd].
Duration pausedDurationInRange({
  required DateTime rangeStart,
  required DateTime rangeEnd,
  required List<SessionPauseInterval> pauseIntervals,
}) {
  if (!rangeEnd.isAfter(rangeStart) || pauseIntervals.isEmpty) {
    return Duration.zero;
  }

  var totalPaused = Duration.zero;
  for (final interval in pauseIntervals) {
    if (!interval.pauseEnd.isAfter(rangeStart) ||
        !rangeEnd.isAfter(interval.pauseStart)) {
      continue;
    }

    final overlapStart = interval.pauseStart.isAfter(rangeStart)
        ? interval.pauseStart
        : rangeStart;
    final overlapEnd = interval.pauseEnd.isBefore(rangeEnd)
        ? interval.pauseEnd
        : rangeEnd;

    if (overlapEnd.isAfter(overlapStart)) {
      totalPaused += overlapEnd.difference(overlapStart);
    }
  }
  return totalPaused;
}
