// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:heart_rate_dashboard/services/database_service.dart';

/// Tests for session history database query methods.
///
/// These tests verify the database operations required for session history
/// management, including querying, deletion, and retention logic.
Future<void> _setSessionTimes(
  DatabaseService db,
  int sessionId, {
  required DateTime start,
  DateTime? end,
}) async {
  final database = await db.database;
  await database.update(
    'workout_sessions',
    {
      'start_time': start.millisecondsSinceEpoch,
      if (end != null) 'end_time': end.millisecondsSinceEpoch,
    },
    where: 'id = ?',
    whereArgs: [sessionId],
  );
}

Future<int> _createCompletedSession(
  DatabaseService db,
  String deviceName, {
  required DateTime start,
  required String name,
  required int avgHr,
  required int minHr,
  required int maxHr,
  DateTime? end,
}) async {
  final sessionId = await db.createSession(
    deviceName: deviceName,
    name: name,
    trackSpeedDistance: false,
  );
  await db.endSession(
    sessionId: sessionId,
    avgHr: avgHr,
    minHr: minHr,
    maxHr: maxHr,
  );
  await _setSessionTimes(
    db,
    sessionId,
    start: start,
    end: end ?? start.add(const Duration(hours: 1)),
  );
  return sessionId;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for testing
  sqfliteFfiInit();

  group('DatabaseService - Session History', () {
    late DatabaseService db;

    setUp(() async {
      db = DatabaseService.instance;
      // Initialize a fresh in-memory database for each test
      await db.initializeForTesting(databaseFactoryFfi);
    });

    tearDown(() async {
      await db.closeForTesting();
    });

    test('getAllCompletedSessions returns only completed sessions', () async {
      // Create a completed session
      final completedSessionId = await db.createSession(
        deviceName: 'Polar H10',
        name: 'Completed',
        trackSpeedDistance: false,
      );
      await db.endSession(
        sessionId: completedSessionId,
        avgHr: 140,
        minHr: 80,
        maxHr: 180,
      );

      // Create an active session (not completed)
      await db.createSession(
        deviceName: 'Garmin HRM',
        name: 'Active',
        trackSpeedDistance: false,
      );

      // Query completed sessions
      final sessions = await db.getAllCompletedSessions();

      // Should return only the completed session
      expect(sessions.length, equals(1));
      expect(sessions[0].id, equals(completedSessionId));
      expect(sessions[0].endTime, isNotNull);
      expect(sessions[0].avgHr, equals(140));
    });

    test(
      'getAllCompletedSessions returns sessions sorted newest first',
      () async {
        final base = DateTime(2025, 1, 1, 12);
        final session1Id = await _createCompletedSession(
          db,
          'Device 1',
          name: 'Session 1',
          start: base,
          avgHr: 130,
          minHr: 70,
          maxHr: 170,
        );
        final session2Id = await _createCompletedSession(
          db,
          'Device 2',
          name: 'Session 2',
          start: base.add(const Duration(minutes: 1)),
          avgHr: 140,
          minHr: 80,
          maxHr: 180,
        );
        final session3Id = await _createCompletedSession(
          db,
          'Device 3',
          name: 'Session 3',
          start: base.add(const Duration(minutes: 2)),
          avgHr: 150,
          minHr: 90,
          maxHr: 190,
        );

        final sessions = await db.getAllCompletedSessions();

        // Should be sorted by start_time DESC (newest first)
        expect(sessions.length, equals(3));
        expect(sessions[0].id, equals(session3Id));
        expect(sessions[1].id, equals(session2Id));
        expect(sessions[2].id, equals(session1Id));
      },
    );

    test('deleteSession removes session and all associated readings', () async {
      // Create a session
      final sessionId = await db.createSession(
        deviceName: 'Test Device',
        name: 'Test Session',
        trackSpeedDistance: false,
      );

      // Add heart rate readings
      await db.insertHeartRateReading(sessionId, DateTime.now(), 120);
      await db.insertHeartRateReading(sessionId, DateTime.now(), 125);
      await db.insertHeartRateReading(sessionId, DateTime.now(), 130);

      // End the session
      await db.endSession(
        sessionId: sessionId,
        avgHr: 125,
        minHr: 120,
        maxHr: 130,
      );

      // Verify session and readings exist
      final sessionBefore = await db.getSessionById(sessionId);
      expect(sessionBefore, isNotNull);
      final readingsBefore = await db.getReadingsBySession(sessionId);
      expect(readingsBefore.length, equals(3));

      // Delete the session
      await db.deleteSession(sessionId);

      // Verify session is deleted
      final sessionAfter = await db.getSessionById(sessionId);
      expect(sessionAfter, isNull);

      // Verify readings are deleted
      final readingsAfter = await db.getReadingsBySession(sessionId);
      expect(readingsAfter.length, equals(0));
    });

    test('deleteAllSessions removes all sessions and readings', () async {
      // Create multiple sessions with readings
      for (var i = 0; i < 3; i++) {
        final sessionId = await db.createSession(
          deviceName: 'Device $i',
          name: 'Session $i',
          trackSpeedDistance: false,
        );
        await db.insertHeartRateReading(sessionId, DateTime.now(), 120 + i);
        await db.insertHeartRateReading(sessionId, DateTime.now(), 125 + i);
        await db.endSession(
          sessionId: sessionId,
          avgHr: 122 + i,
          minHr: 120 + i,
          maxHr: 125 + i,
        );
      }

      // Verify sessions exist
      final sessionsBefore = await db.getAllCompletedSessions();
      expect(sessionsBefore.length, greaterThan(0));

      // Delete all sessions
      await db.deleteAllSessions();

      // Verify all sessions are deleted
      final sessionsAfter = await db.getAllCompletedSessions();
      expect(sessionsAfter.length, equals(0));
    });

    test('getSessionsOlderThan returns sessions before cutoff date', () async {
      final now = DateTime.now();

      // Create old session
      final oldStart = now.subtract(const Duration(days: 60));
      final recentStart = now.subtract(const Duration(days: 5));

      final oldSessionId = await _createCompletedSession(
        db,
        'Old Device',
        name: 'Old Session',
        start: oldStart,
        avgHr: 130,
        minHr: 70,
        maxHr: 170,
        end: oldStart.add(const Duration(hours: 1)),
      );

      // Create recent session
      await _createCompletedSession(
        db,
        'Recent Device',
        name: 'Recent Session',
        start: recentStart,
        avgHr: 140,
        minHr: 80,
        maxHr: 180,
        end: recentStart.add(const Duration(hours: 1)),
      );

      // Query for sessions older than 30 days
      final cutoffDate = now.subtract(const Duration(days: 30));
      final oldSessions = await db.getSessionsOlderThan(cutoffDate);

      // Verify the query executes successfully and returns a list containing the old session
      expect(oldSessions.map((s) => s.id), contains(oldSessionId));
    });

    test(
      'getPreviousSession returns session with earlier start_time',
      () async {
        // Create three sessions with small delays
        final base = DateTime(2025, 1, 1, 12);
        final session1Id = await _createCompletedSession(
          db,
          'Device 1',
          name: 'Session 1',
          start: base,
          avgHr: 130,
          minHr: 70,
          maxHr: 170,
        );
        final session2Id = await _createCompletedSession(
          db,
          'Device 2',
          name: 'Session 2',
          start: base.add(const Duration(minutes: 1)),
          avgHr: 140,
          minHr: 80,
          maxHr: 180,
        );
        await _createCompletedSession(
          db,
          'Device 3',
          name: 'Session 3',
          start: base.add(const Duration(minutes: 2)),
          avgHr: 150,
          minHr: 90,
          maxHr: 190,
        );

        // Get previous session for session2
        final previousSession = await db.getPreviousSession(session2Id);

        expect(previousSession, isNotNull);
        expect(previousSession!.id, equals(session1Id));
      },
    );

    test('getNextSession returns session with later start_time', () async {
      // Create three sessions with small delays
      final base = DateTime(2025, 1, 1, 12);
      final session2Id = await _createCompletedSession(
        db,
        'Device 2',
        name: 'Session 2',
        start: base.add(const Duration(minutes: 1)),
        avgHr: 140,
        minHr: 80,
        maxHr: 180,
      );
      final session3Id = await _createCompletedSession(
        db,
        'Device 3',
        name: 'Session 3',
        start: base.add(const Duration(minutes: 2)),
        avgHr: 150,
        minHr: 90,
        maxHr: 190,
      );

      // Get next session for session2
      final nextSession = await db.getNextSession(session2Id);

      expect(nextSession, isNotNull);
      expect(nextSession!.id, equals(session3Id));
    });

    test('getPreviousSession returns null for oldest session', () async {
      final sessionId = await db.createSession(
        deviceName: 'Only Device',
        name: 'Only Session',
        trackSpeedDistance: false,
      );
      await db.endSession(
        sessionId: sessionId,
        avgHr: 130,
        minHr: 70,
        maxHr: 170,
      );

      final previousSession = await db.getPreviousSession(sessionId);

      expect(previousSession, isNull);
    });
  });
}
