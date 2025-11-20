import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workout_tracker/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService databaseService;

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
  });

  setUp(() async {
    // Use in-memory database with FFI for testing
    databaseService = DatabaseService.instance;
    await databaseService.initializeForTesting(databaseFactoryFfi);
  });

  tearDown(() async {
    await databaseService.closeForTesting();
  });

  group('DatabaseService', () {
    test('database initializes successfully', () async {
      // Verify database is initialized and accessible
      final db = await databaseService.database;
      expect(db, isNotNull);
      expect(db.isOpen, isTrue);
    });

    test('creates and retrieves session', () async {
      // Create a new session
      final sessionId = await databaseService.createSession('Test Device');
      expect(sessionId, greaterThan(0));

      // Retrieve the current session
      final session = await databaseService.getCurrentSession();
      expect(session, isNotNull);
      expect(session!.id, equals(sessionId));
      expect(session.deviceName, equals('Test Device'));
      expect(session.endTime, isNull);
    });

    test('inserts and retrieves heart rate readings by session', () async {
      // Create a session
      final sessionId = await databaseService.createSession('Test Device');

      // Insert heart rate readings
      final timestamp1 = DateTime.now();
      final timestamp2 = timestamp1.add(const Duration(seconds: 2));

      await databaseService.insertHeartRateReading(sessionId, timestamp1, 120);
      await databaseService.insertHeartRateReading(sessionId, timestamp2, 125);

      // Retrieve readings by session
      final readings = await databaseService.getReadingsBySession(sessionId);
      expect(readings.length, equals(2));
      expect(readings[0].sessionId, equals(sessionId));
      expect(readings[0].bpm, equals(120));
      expect(readings[1].bpm, equals(125));
    });

    test('ends session with statistics', () async {
      // Create a session
      final sessionId = await databaseService.createSession('Test Device');

      // End the session with statistics
      await databaseService.endSession(
        sessionId: sessionId,
        avgHr: 130,
        minHr: 110,
        maxHr: 150,
      );

      // Verify the session has end time and statistics
      final sessions = await databaseService.getSessionById(sessionId);
      expect(sessions, isNotNull);
      expect(sessions!.endTime, isNotNull);
      expect(sessions.avgHr, equals(130));
      expect(sessions.minHr, equals(110));
      expect(sessions.maxHr, equals(150));
    });

    test('stores and retrieves settings', () async {
      // Set a setting
      await databaseService.setSetting('user_age', '30');

      // Retrieve the setting
      final value = await databaseService.getSetting('user_age');
      expect(value, equals('30'));
    });

    test('queries readings by session and time range', () async {
      // Create a session
      final sessionId = await databaseService.createSession('Test Device');

      // Insert readings at different times
      final baseTime = DateTime.now();
      await databaseService.insertHeartRateReading(sessionId, baseTime, 120);
      await databaseService.insertHeartRateReading(
        sessionId,
        baseTime.add(const Duration(seconds: 30)),
        125,
      );
      await databaseService.insertHeartRateReading(
        sessionId,
        baseTime.add(const Duration(seconds: 60)),
        130,
      );

      // Query readings in a specific time range
      final readings = await databaseService.getReadingsBySessionAndTimeRange(
        sessionId,
        baseTime.add(const Duration(seconds: 20)),
        baseTime.add(const Duration(seconds: 50)),
      );

      // Should only get the middle reading
      expect(readings.length, equals(1));
      expect(readings[0].bpm, equals(125));
    });
  });
}
