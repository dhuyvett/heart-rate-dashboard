import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/workout_session.dart';
import 'package:heart_rate_dashboard/screens/session_detail_screen.dart';

void main() {
  group('SessionDetailScreen', () {
    testWidgets('renders with basic session data', (WidgetTester tester) async {
      // Create test session
      final session = WorkoutSession(
        id: 1,
        deviceName: 'Test Device',
        startTime: DateTime(2025, 11, 25, 14, 30),
        endTime: DateTime(2025, 11, 25, 15, 30),
        avgHr: 140,
        minHr: 120,
        maxHr: 160,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: SessionDetailScreen(session: session)),
        ),
      );

      // Verify screen is rendered and loading indicator shows initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Pump a few frames to allow async loading
      await tester.pump(const Duration(milliseconds: 100));

      // Verify device name in AppBar
      expect(find.text('Test Device'), findsOneWidget);

      // Verify navigation buttons are present
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('delete button shows confirmation dialog', (
      WidgetTester tester,
    ) async {
      final session = WorkoutSession(
        id: 3,
        deviceName: 'Test Device',
        startTime: DateTime(2025, 11, 25, 14, 30),
        endTime: DateTime(2025, 11, 25, 15, 30),
        avgHr: 140,
        minHr: 120,
        maxHr: 160,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: SessionDetailScreen(session: session)),
        ),
      );

      // Wait for screen to load
      await tester.pump(const Duration(milliseconds: 100));

      // Tap delete button in AppBar
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify confirmation dialog is shown
      expect(
        find.text('Delete this session? This action cannot be undone.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('AppBar has correct structure', (WidgetTester tester) async {
      final session = WorkoutSession(
        id: 4,
        deviceName: 'My HRM Device',
        startTime: DateTime(2025, 11, 25, 14, 30),
        endTime: DateTime(2025, 11, 25, 15, 30),
        avgHr: 140,
        minHr: 120,
        maxHr: 160,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: SessionDetailScreen(session: session)),
        ),
      );

      await tester.pump();

      // Verify AppBar structure
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('My HRM Device'), findsOneWidget);

      // Verify action buttons in AppBar
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, isNotNull);
      expect(appBar.actions!.length, equals(3));
    });

    testWidgets('uses ConsumerStatefulWidget pattern', (
      WidgetTester tester,
    ) async {
      final session = WorkoutSession(
        id: 5,
        deviceName: 'Test Device',
        startTime: DateTime(2025, 11, 25, 14, 30),
        endTime: DateTime(2025, 11, 25, 15, 30),
        avgHr: 140,
        minHr: 120,
        maxHr: 160,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: SessionDetailScreen(session: session)),
        ),
      );

      await tester.pump();

      // Verify SessionDetailScreen is a ConsumerStatefulWidget (by checking it renders)
      expect(find.byType(SessionDetailScreen), findsOneWidget);

      // Verify Scaffold is present
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows loading state initially', (WidgetTester tester) async {
      final session = WorkoutSession(
        id: 6,
        deviceName: 'Test Device',
        startTime: DateTime(2025, 11, 25, 14, 30),
        endTime: DateTime(2025, 11, 25, 15, 30),
        avgHr: 140,
        minHr: 120,
        maxHr: 160,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: SessionDetailScreen(session: session)),
        ),
      );

      // Should show loading indicator immediately
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
