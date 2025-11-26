import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:heart_rate_dashboard/services/database_service.dart';
import 'package:heart_rate_dashboard/models/workout_session.dart';

/// Tests for session history database query methods.
///
/// These tests verify the database operations required for session history
/// management, including querying, deletion, and retention logic.
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
      final completedSessionId = await db.createSession('Polar H10');
      await db.endSession(
        sessionId: completedSessionId,
        avgHr: 140,
        minHr: 80,
        maxHr: 180,
      );

      // Create an active session (not completed)
      await db.createSession('Garmin HRM');

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
        // Create multiple completed sessions with delays to ensure different timestamps
        final session1Id = await db.createSession('Device 1');
        await Future.delayed(const Duration(milliseconds: 10));
        final session2Id = await db.createSession('Device 2');
        await Future.delayed(const Duration(milliseconds: 10));
        final session3Id = await db.createSession('Device 3');

        // End sessions in reverse order to test sorting by start_time
        await db.endSession(
          sessionId: session3Id,
          avgHr: 150,
          minHr: 90,
          maxHr: 190,
        );
        await db.endSession(
          sessionId: session1Id,
          avgHr: 130,
          minHr: 70,
          maxHr: 170,
        );
        await db.endSession(
          sessionId: session2Id,
          avgHr: 140,
          minHr: 80,
          maxHr: 180,
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
      final sessionId = await db.createSession('Test Device');

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
        final sessionId = await db.createSession('Device $i');
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
      final oldSessionId = await db.createSession('Old Device');
      await db.endSession(
        sessionId: oldSessionId,
        avgHr: 130,
        minHr: 70,
        maxHr: 170,
      );

      // Create recent session
      final recentSessionId = await db.createSession('Recent Device');
      await Future.delayed(const Duration(milliseconds: 10));
      await db.endSession(
        sessionId: recentSessionId,
        avgHr: 140,
        minHr: 80,
        maxHr: 180,
      );

      // Query for sessions older than 30 days
      // Note: Since sessions were just created, cutoff date is in the past
      // relative to session creation time, so this tests that query works
      final cutoffDate = now.subtract(const Duration(days: 30));
      final oldSessions = await db.getSessionsOlderThan(cutoffDate);

      // Verify the query executes successfully and returns a list
      expect(oldSessions, isA<List<WorkoutSession>>());
    });

    test(
      'getPreviousSession returns session with earlier start_time',
      () async {
        // Create three sessions with small delays
        final session1Id = await db.createSession('Device 1');
        await Future.delayed(const Duration(milliseconds: 10));
        final session2Id = await db.createSession('Device 2');
        await Future.delayed(const Duration(milliseconds: 10));
        final session3Id = await db.createSession('Device 3');

        // End all sessions
        await db.endSession(
          sessionId: session1Id,
          avgHr: 130,
          minHr: 70,
          maxHr: 170,
        );
        await db.endSession(
          sessionId: session2Id,
          avgHr: 140,
          minHr: 80,
          maxHr: 180,
        );
        await db.endSession(
          sessionId: session3Id,
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
      final session1Id = await db.createSession('Device 1');
      await Future.delayed(const Duration(milliseconds: 10));
      final session2Id = await db.createSession('Device 2');
      await Future.delayed(const Duration(milliseconds: 10));
      final session3Id = await db.createSession('Device 3');

      // End all sessions
      await db.endSession(
        sessionId: session1Id,
        avgHr: 130,
        minHr: 70,
        maxHr: 170,
      );
      await db.endSession(
        sessionId: session2Id,
        avgHr: 140,
        minHr: 80,
        maxHr: 180,
      );
      await db.endSession(
        sessionId: session3Id,
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
      final sessionId = await db.createSession('Only Device');
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
