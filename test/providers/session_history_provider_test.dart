// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/providers/session_history_provider.dart';
import 'package:heart_rate_dashboard/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<int> _createCompletedSession(
  String deviceName,
  DateTime startTime, {
  required int avgHr,
  required int minHr,
  required int maxHr,
}) async {
  final sessionId = await DatabaseService.instance.createSession(deviceName);
  await DatabaseService.instance.endSession(
    sessionId: sessionId,
    avgHr: avgHr,
    minHr: minHr,
    maxHr: maxHr,
  );

  final db = await DatabaseService.instance.database;
  await db.update(
    'workout_sessions',
    {
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': startTime
          .add(const Duration(hours: 1))
          .millisecondsSinceEpoch,
    },
    where: 'id = ?',
    whereArgs: [sessionId],
  );

  return sessionId;
}

void main() {
  late ProviderContainer container;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Initialize sqflite_ffi for testing
    sqfliteFfiInit();
    await DatabaseService.instance.initializeForTesting(databaseFactoryFfi);

    // Create a new provider container
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await DatabaseService.instance.closeForTesting();
  });

  group('SessionHistoryProvider', () {
    test('loads all completed sessions sorted newest first', () async {
      // Create test sessions
      final base = DateTime(2025, 1, 1, 12);
      final session1Id = await _createCompletedSession(
        'Device 1',
        base,
        avgHr: 120,
        minHr: 100,
        maxHr: 140,
      );
      final session2Id = await _createCompletedSession(
        'Device 2',
        base.add(const Duration(minutes: 1)),
        avgHr: 130,
        minHr: 110,
        maxHr: 150,
      );
      final session3Id = await _createCompletedSession(
        'Device 3',
        base.add(const Duration(minutes: 2)),
        avgHr: 140,
        minHr: 120,
        maxHr: 160,
      );

      // Load sessions
      final notifier = container.read(sessionHistoryProvider.notifier);
      await notifier.loadSessions();

      final state = container.read(sessionHistoryProvider);
      expect(state.length, 3);
      expect(state[0].id, session3Id); // Newest first
      expect(state[1].id, session2Id);
      expect(state[2].id, session1Id);
    });

    test('empty state when no completed sessions exist', () async {
      // Load sessions without creating any
      final notifier = container.read(sessionHistoryProvider.notifier);
      await notifier.loadSessions();

      final state = container.read(sessionHistoryProvider);
      expect(state, isEmpty);
    });

    test('deleteSession removes session and updates list', () async {
      // Create and end a session
      final sessionId = await DatabaseService.instance.createSession(
        'Device 1',
      );
      await DatabaseService.instance.endSession(
        sessionId: sessionId,
        avgHr: 120,
        minHr: 100,
        maxHr: 140,
      );

      // Load sessions
      final notifier = container.read(sessionHistoryProvider.notifier);
      await notifier.loadSessions();
      expect(container.read(sessionHistoryProvider).length, 1);

      // Delete session
      await notifier.deleteSession(sessionId);

      // Verify session is removed from state
      final state = container.read(sessionHistoryProvider);
      expect(state, isEmpty);

      // Verify session is removed from database
      final sessions = await DatabaseService.instance.getAllCompletedSessions();
      expect(sessions, isEmpty);
    });

    test('deleteAllSessions removes all sessions and clears list', () async {
      // Create multiple sessions
      final session1Id = await DatabaseService.instance.createSession(
        'Device 1',
      );
      final session2Id = await DatabaseService.instance.createSession(
        'Device 2',
      );

      await DatabaseService.instance.endSession(
        sessionId: session1Id,
        avgHr: 120,
        minHr: 100,
        maxHr: 140,
      );
      await DatabaseService.instance.endSession(
        sessionId: session2Id,
        avgHr: 130,
        minHr: 110,
        maxHr: 150,
      );

      // Load sessions
      final notifier = container.read(sessionHistoryProvider.notifier);
      await notifier.loadSessions();
      expect(container.read(sessionHistoryProvider).length, 2);

      // Delete all sessions
      await notifier.deleteAllSessions();

      // Verify all sessions are removed from state
      final state = container.read(sessionHistoryProvider);
      expect(state, isEmpty);

      // Verify all sessions are removed from database
      final sessions = await DatabaseService.instance.getAllCompletedSessions();
      expect(sessions, isEmpty);
    });
  });
}
