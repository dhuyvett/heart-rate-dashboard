// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/session_pause_interval.dart';
import 'package:heart_rate_dashboard/utils/session_timeline.dart';

void main() {
  group('session timeline math', () {
    test('activeDurationInRange excludes paused overlap', () {
      final start = DateTime(2026, 1, 1, 8, 0, 0);
      final end = start.add(const Duration(minutes: 10));
      final pauses = [
        SessionPauseInterval(
          id: 1,
          sessionId: 42,
          pauseStart: start.add(const Duration(minutes: 2)),
          pauseEnd: start.add(const Duration(minutes: 4)),
        ),
      ];

      final active = activeDurationInRange(
        rangeStart: start,
        rangeEnd: end,
        pauseIntervals: pauses,
      );

      expect(active, const Duration(minutes: 8));
    });

    test('activeElapsedSecondsAt clips multiple pause intervals', () {
      final start = DateTime(2026, 1, 1, 8, 0, 0);
      final target = start.add(const Duration(minutes: 20));
      final pauses = [
        SessionPauseInterval(
          id: 1,
          sessionId: 42,
          pauseStart: start.add(const Duration(minutes: 3)),
          pauseEnd: start.add(const Duration(minutes: 6)),
        ),
        SessionPauseInterval(
          id: 2,
          sessionId: 42,
          pauseStart: start.add(const Duration(minutes: 10)),
          pauseEnd: start.add(const Duration(minutes: 12)),
        ),
      ];

      final activeSeconds = activeElapsedSecondsAt(
        sessionStart: start,
        timestamp: target,
        pauseIntervals: pauses,
      );

      expect(activeSeconds, 900); // 20m elapsed - 5m paused = 15m.
    });
  });
}
