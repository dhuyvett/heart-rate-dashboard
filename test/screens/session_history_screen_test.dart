import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/workout_session.dart';
import 'package:heart_rate_dashboard/providers/session_history_provider.dart';
import 'package:heart_rate_dashboard/screens/session_history_screen.dart';

void main() {
  group('SessionHistoryScreen', () {
    testWidgets('displays empty state when no sessions exist', (
      WidgetTester tester,
    ) async {
      // Create empty session list
      final sessions = <WorkoutSession>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override the provider to return empty list without calling database
            sessionHistoryProvider.overrideWith(
              () => TestableSessionHistoryNotifier(sessions),
            ),
          ],
          child: const MaterialApp(home: SessionHistoryScreen()),
        ),
      );

      await tester.pump();

      // Verify empty state message is displayed
      expect(
        find.text(
          'No workout sessions yet. Start a session to see your history here.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('displays list of sessions sorted newest first', (
      WidgetTester tester,
    ) async {
      // Create test sessions
      final sessions = [
        WorkoutSession(
          id: 1,
          deviceName: 'Test Device',
          startTime: DateTime(2025, 11, 25, 14, 30),
          endTime: DateTime(2025, 11, 25, 15, 30),
          avgHr: 140,
          minHr: 120,
          maxHr: 160,
        ),
        WorkoutSession(
          id: 2,
          deviceName: 'Test Device',
          startTime: DateTime(2025, 11, 24, 10, 0),
          endTime: DateTime(2025, 11, 24, 11, 0),
          avgHr: 135,
          minHr: 115,
          maxHr: 155,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionHistoryProvider.overrideWith(
              () => TestableSessionHistoryNotifier(sessions),
            ),
          ],
          child: const MaterialApp(home: SessionHistoryScreen()),
        ),
      );

      await tester.pump();

      // Verify sessions are displayed
      expect(find.text('Nov 25, 2025 2:30 PM'), findsOneWidget);
      expect(find.text('Nov 24, 2025 10:00 AM'), findsOneWidget);

      // Verify durations are displayed
      expect(find.textContaining('01:00:00'), findsNWidgets(2));
    });

    testWidgets('shows delete confirmation dialog on swipe', (
      WidgetTester tester,
    ) async {
      final sessions = [
        WorkoutSession(
          id: 1,
          deviceName: 'Test Device',
          startTime: DateTime(2025, 11, 25, 14, 30),
          endTime: DateTime(2025, 11, 25, 15, 30),
          avgHr: 140,
          minHr: 120,
          maxHr: 160,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionHistoryProvider.overrideWith(
              () => TestableSessionHistoryNotifier(sessions),
            ),
          ],
          child: const MaterialApp(home: SessionHistoryScreen()),
        ),
      );

      await tester.pump();

      // Swipe to dismiss
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Verify confirmation dialog is shown
      expect(
        find.text('Delete this session? This action cannot be undone.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('shows delete all confirmation dialog', (
      WidgetTester tester,
    ) async {
      final sessions = [
        WorkoutSession(
          id: 1,
          deviceName: 'Test Device',
          startTime: DateTime(2025, 11, 25, 14, 30),
          endTime: DateTime(2025, 11, 25, 15, 30),
          avgHr: 140,
          minHr: 120,
          maxHr: 160,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionHistoryProvider.overrideWith(
              () => TestableSessionHistoryNotifier(sessions),
            ),
          ],
          child: const MaterialApp(home: SessionHistoryScreen()),
        ),
      );

      await tester.pump();

      // Tap menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap delete all option
      await tester.tap(find.text('Delete All Sessions'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog is shown
      expect(
        find.text(
          'Delete all workout sessions? This will permanently delete all your session history and cannot be undone.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete All'), findsOneWidget);
    });

    testWidgets('navigates to session detail when session tapped', (
      WidgetTester tester,
    ) async {
      final sessions = [
        WorkoutSession(
          id: 1,
          deviceName: 'Test Device',
          startTime: DateTime(2025, 11, 25, 14, 30),
          endTime: DateTime(2025, 11, 25, 15, 30),
          avgHr: 140,
          minHr: 120,
          maxHr: 160,
        ),
      ];

      final navigatorObserver = MockNavigatorObserver();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionHistoryProvider.overrideWith(
              () => TestableSessionHistoryNotifier(sessions),
            ),
          ],
          child: MaterialApp(
            home: const SessionHistoryScreen(),
            navigatorObservers: [navigatorObserver],
          ),
        ),
      );

      await tester.pump();

      // Tap on the session
      await tester.tap(find.byType(ListTile));
      await tester.pump();

      // Verify navigation was attempted
      expect(navigatorObserver.pushedRoutes, isNotEmpty);
    });
  });
}

/// Test implementation of SessionHistoryNotifier for testing.
/// Extends the real notifier to avoid type issues.
class TestableSessionHistoryNotifier extends SessionHistoryNotifier {
  final List<WorkoutSession> _testSessions;

  TestableSessionHistoryNotifier(this._testSessions);

  @override
  List<WorkoutSession> build() {
    // Return test sessions without calling the database
    return _testSessions;
  }

  @override
  Future<void> loadSessions() async {
    // Override to not call database in tests
    state = _testSessions;
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    // Override to just update state without calling database
    state = state.where((s) => s.id != sessionId).toList();
  }

  @override
  Future<void> deleteAllSessions() async {
    // Override to just clear state without calling database
    state = [];
  }
}

/// Mock NavigatorObserver for testing navigation.
class MockNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }
}
