// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/app_settings.dart';
import 'package:heart_rate_dashboard/models/workout_session.dart';
import 'package:heart_rate_dashboard/providers/settings_provider.dart';
import 'package:heart_rate_dashboard/screens/session_detail_screen.dart';

import '../helpers/fake_settings_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildScreen(WorkoutSession session) {
    return ProviderScope(
      overrides: [
        settingsProvider.overrideWith(
          () => FakeSettingsNotifier(const AppSettings()),
        ),
      ],
      child: MaterialApp(home: SessionDetailScreen(session: session)),
    );
  }

  group('SessionDetailScreen', () {
    testWidgets('renders with basic session data', (WidgetTester tester) async {
      // Create test session
      final session = WorkoutSession(
        id: 1,
        deviceName: 'Test Device',
        name: 'Session 1',
        startTime: DateTime(2025, 11, 25, 14, 30),
        endTime: DateTime(2025, 11, 25, 15, 30),
        avgHr: 140,
        minHr: 120,
        maxHr: 160,
      );

      await tester.pumpWidget(buildScreen(session));

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
        name: 'Session 3',
        startTime: DateTime(2025, 11, 25, 14, 30),
        endTime: DateTime(2025, 11, 25, 15, 30),
        avgHr: 140,
        minHr: 120,
        maxHr: 160,
      );

      await tester.pumpWidget(buildScreen(session));

      // Wait for screen to load
      await tester.pump(const Duration(milliseconds: 100));

      // Tap delete button in AppBar
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();
      // Allow dialog animation to start without waiting indefinitely
      await tester.pump(const Duration(milliseconds: 200));

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
        name: 'Session 4',
        startTime: DateTime(2025, 11, 25, 14, 30),
        endTime: DateTime(2025, 11, 25, 15, 30),
        avgHr: 140,
        minHr: 120,
        maxHr: 160,
      );

      await tester.pumpWidget(buildScreen(session));

      await tester.pump();

      // Verify AppBar structure
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('My HRM Device'), findsOneWidget);

      // Verify action buttons in AppBar
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, isNotNull);
      expect(appBar.actions!.length, equals(4)); // prev, next, rename, delete
    });

    testWidgets('uses ConsumerStatefulWidget pattern', (
      WidgetTester tester,
    ) async {
      final session = WorkoutSession(
        id: 5,
        deviceName: 'Test Device',
        name: 'Session 5',
        startTime: DateTime(2025, 11, 25, 14, 30),
        endTime: DateTime(2025, 11, 25, 15, 30),
        avgHr: 140,
        minHr: 120,
        maxHr: 160,
      );

      await tester.pumpWidget(buildScreen(session));

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
        name: 'Session 6',
        startTime: DateTime(2025, 11, 25, 14, 30),
        endTime: DateTime(2025, 11, 25, 15, 30),
        avgHr: 140,
        minHr: 120,
        maxHr: 160,
      );

      await tester.pumpWidget(buildScreen(session));

      // Should show loading indicator immediately
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
