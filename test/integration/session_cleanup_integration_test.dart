// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Session cleanup', () {
    setUp(() async {
      sqfliteFfiInit();
      await DatabaseService.instance.initializeForTesting(databaseFactoryFfi);
    });

    tearDown(() async {
      await DatabaseService.instance.closeForTesting();
    });

    test('deletes empty active session when no readings exist', () async {
      final sessionId = await DatabaseService.instance.createSession(
        deviceName: 'Test Device',
        name: 'Crashed Session',
        trackSpeedDistance: false,
      );

      await DatabaseService.instance.completeActiveSessionWithLastReading();

      final session = await DatabaseService.instance.getSessionById(sessionId);
      expect(session, isNull);
    });

    test('reconstructs stats for interrupted session', () async {
      final db = DatabaseService.instance;
      final sessionId = await db.createSession(
        deviceName: 'Test Device',
        name: 'Crashed Session',
        trackSpeedDistance: false,
      );

      final firstReadingTime = DateTime(2024, 1, 1, 12);
      await db.insertHeartRateReading(sessionId, firstReadingTime, 100);
      await db.insertHeartRateReading(
        sessionId,
        firstReadingTime.add(const Duration(seconds: 5)),
        80,
      );

      await db.completeActiveSessionWithLastReading();

      final session = await db.getSessionById(sessionId);

      expect(session, isNotNull);
      expect(session!.avgHr, equals(90));
      expect(session.minHr, equals(80));
      expect(session.maxHr, equals(100));
      expect(
        session.endTime,
        equals(firstReadingTime.add(const Duration(seconds: 5))),
      );
      expect(await db.getCurrentSession(), isNull);
    });

    test(
      'closes open pause interval when recovering interrupted active session',
      () async {
        final db = DatabaseService.instance;
        final sessionId = await db.createSession(
          deviceName: 'Test Device',
          name: 'Paused Crashed Session',
          trackSpeedDistance: false,
        );

        final readingTime = DateTime(2024, 1, 1, 12, 0, 10);
        final pauseStart = DateTime(2024, 1, 1, 12, 0, 5);

        await db.insertHeartRateReading(sessionId, readingTime, 120);
        await db.startPauseInterval(
          sessionId: sessionId,
          pauseStart: pauseStart,
        );

        await db.completeActiveSessionWithLastReading();

        final intervals = await db.getPauseIntervalsBySession(sessionId);
        expect(intervals.length, equals(1));
        expect(intervals.first.pauseStart, equals(pauseStart));
        expect(intervals.first.pauseEnd, equals(readingTime));
      },
    );
  });
}
