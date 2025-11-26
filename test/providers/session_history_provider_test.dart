import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/providers/session_history_provider.dart';
import 'package:heart_rate_dashboard/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late ProviderContainer container;

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
      final session1Id = await DatabaseService.instance.createSession(
        'Device 1',
      );
      await Future.delayed(const Duration(milliseconds: 10));
      final session2Id = await DatabaseService.instance.createSession(
        'Device 2',
      );
      await Future.delayed(const Duration(milliseconds: 10));
      final session3Id = await DatabaseService.instance.createSession(
        'Device 3',
      );

      // End sessions
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
      await DatabaseService.instance.endSession(
        sessionId: session3Id,
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
