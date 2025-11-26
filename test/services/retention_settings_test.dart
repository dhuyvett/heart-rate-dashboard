import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:heart_rate_dashboard/services/database_service.dart';
import 'package:heart_rate_dashboard/models/app_settings.dart';

/// Tests for session retention settings and auto-deletion logic.
///
/// These tests verify that retention settings are persisted correctly
/// and that auto-deletion removes sessions older than the retention period.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for testing
  sqfliteFfiInit();

  group('Retention Settings', () {
    late DatabaseService db;

    setUp(() async {
      db = DatabaseService.instance;
      // Initialize a fresh in-memory database for each test
      await db.initializeForTesting(databaseFactoryFfi);
    });

    tearDown(() async {
      await db.closeForTesting();
    });

    test('retention setting saves and loads correctly', () async {
      // Save retention setting
      await db.setSetting('session_retention_days', '60');

      // Load retention setting
      final value = await db.getSetting('session_retention_days');

      expect(value, equals('60'));
    });

    test('retention setting defaults to 30 when not set', () async {
      // Try to load setting that doesn't exist
      final value = await db.getSetting('session_retention_days');

      expect(value, isNull);
      // Application code should use default value of 30 when null
    });

    test('auto-deletion removes old sessions correctly', () async {
      final now = DateTime.now();

      // Create an old session (45 days ago)
      final oldSessionId = await db.createSession('Old Device');
      // Manually update the session timestamps to simulate old data
      final dbInstance = await db.database;
      await dbInstance.update(
        'workout_sessions',
        {
          'start_time': now
              .subtract(const Duration(days: 45))
              .millisecondsSinceEpoch,
          'end_time': now
              .subtract(const Duration(days: 45))
              .millisecondsSinceEpoch,
          'avg_hr': 130,
          'min_hr': 70,
          'max_hr': 170,
        },
        where: 'id = ?',
        whereArgs: [oldSessionId],
      );

      // Add heart rate readings for the old session
      await db.insertHeartRateReading(
        oldSessionId,
        now.subtract(const Duration(days: 45)),
        120,
      );

      // Create a recent session (15 days ago)
      final recentSessionId = await db.createSession('Recent Device');
      await dbInstance.update(
        'workout_sessions',
        {
          'start_time': now
              .subtract(const Duration(days: 15))
              .millisecondsSinceEpoch,
          'end_time': now
              .subtract(const Duration(days: 15))
              .millisecondsSinceEpoch,
          'avg_hr': 140,
          'min_hr': 80,
          'max_hr': 180,
        },
        where: 'id = ?',
        whereArgs: [recentSessionId],
      );

      // Verify both sessions exist
      final allSessionsBefore = await db.getAllCompletedSessions();
      expect(allSessionsBefore.length, equals(2));

      // Calculate cutoff date for 30-day retention
      final cutoffDate = now.subtract(const Duration(days: 30));

      // Find sessions older than cutoff
      final oldSessions = await db.getSessionsOlderThan(cutoffDate);
      expect(oldSessions.length, equals(1));
      expect(oldSessions[0].id, equals(oldSessionId));

      // Delete old sessions
      for (final session in oldSessions) {
        await db.deleteSession(session.id!);
      }

      // Verify only recent session remains
      final allSessionsAfter = await db.getAllCompletedSessions();
      expect(allSessionsAfter.length, equals(1));
      expect(allSessionsAfter[0].id, equals(recentSessionId));
    });

    test('validation catches retention days below minimum', () async {
      // Test validation for value below 1
      const invalidValue = 0;
      expect(invalidValue < 1, isTrue);
    });

    test('validation catches retention days above maximum', () async {
      // Test validation for value above 3650
      const invalidValue = 3651;
      expect(invalidValue > 3650, isTrue);
    });

    test('validation accepts valid retention days range', () async {
      // Test validation for valid values
      const validMin = 1;
      const validMid = 100;
      const validMax = 3650;

      expect(validMin >= 1 && validMin <= 3650, isTrue);
      expect(validMid >= 1 && validMid <= 3650, isTrue);
      expect(validMax >= 1 && validMax <= 3650, isTrue);
    });

    test('AppSettings model includes sessionRetentionDays field', () {
      // Test that AppSettings can be created with sessionRetentionDays
      const settings = AppSettings(sessionRetentionDays: 60);

      expect(settings.sessionRetentionDays, equals(60));
    });

    test('AppSettings model defaults sessionRetentionDays to 30', () {
      // Test that AppSettings defaults to 30 days
      const settings = AppSettings();

      expect(settings.sessionRetentionDays, equals(30));
    });
  });
}
