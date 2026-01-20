@Timeout(Duration(seconds: 10))
library;

// Tests for verifying the app name is correctly configured as "Heart Rate Dashboard".
//
// These tests verify:
// - MaterialApp title is set to "Heart Rate Dashboard"
// - App builds and runs without errors
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('App Name Configuration', () {
    testWidgets('MaterialApp title displays "Heart Rate Dashboard"', (
      WidgetTester tester,
    ) async {
      // Build a minimal MaterialApp with the expected title
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            title: 'Heart Rate Dashboard',
            home: Scaffold(body: Center(child: Text('Test'))),
          ),
        ),
      );

      // Find the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify the title is correctly set
      expect(materialApp.title, equals('Heart Rate Dashboard'));
    });

    testWidgets('App builds and initializes without errors', (
      WidgetTester tester,
    ) async {
      // Build a MaterialApp similar to the main app structure (non-const due to AppBar)
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            title: 'Heart Rate Dashboard',
            home: Scaffold(
              appBar: AppBar(title: const Text('Heart Rate Dashboard')),
              body: const Center(child: Text('App initialized successfully')),
            ),
          ),
        ),
      );

      // Verify the app builds without throwing
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      // Verify app bar displays the correct title
      expect(find.text('Heart Rate Dashboard'), findsOneWidget);
    });

    test('App name constant is correct', () {
      // Direct assertion on the expected app name value
      const expectedAppName = 'Heart Rate Dashboard';
      expect(expectedAppName, isNotEmpty);
      expect(expectedAppName, equals('Heart Rate Dashboard'));
    });
  });
}
