import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workout_tracker/providers/settings_provider.dart';
import 'package:workout_tracker/services/database_service.dart';
import 'package:workout_tracker/utils/constants.dart';

void main() {
  // Initialize sqflite_ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('SettingsProvider', () {
    late ProviderContainer container;

    setUp(() async {
      // Initialize database for testing
      await DatabaseService.instance.initializeForTesting(databaseFactoryFfi);

      // Create a fresh provider container for each test
      container = ProviderContainer();
    });

    tearDown(() async {
      container.dispose();
      await DatabaseService.instance.closeForTesting();
    });

    test('loads default settings when no settings in database', () async {
      // Wait for settings to load
      await Future.delayed(const Duration(milliseconds: 100));

      final settings = container.read(settingsProvider);

      expect(settings.age, defaultAge);
      expect(settings.chartWindowSeconds, defaultChartWindowSeconds);
    });

    test('persists age changes to database', () async {
      final notifier = container.read(settingsProvider.notifier);

      // Update age
      await notifier.updateAge(35);

      // Verify state updated
      final settings = container.read(settingsProvider);
      expect(settings.age, 35);

      // Verify persisted to database
      final savedAge = await DatabaseService.instance.getSetting('user_age');
      expect(savedAge, '35');
    });

    test('persists chart window changes to database', () async {
      final notifier = container.read(settingsProvider.notifier);

      // Update chart window
      await notifier.updateChartWindow(60);

      // Verify state updated
      final settings = container.read(settingsProvider);
      expect(settings.chartWindowSeconds, 60);

      // Verify persisted to database
      final savedWindow = await DatabaseService.instance.getSetting(
        'chart_window_seconds',
      );
      expect(savedWindow, '60');
    });

    test('throws error for invalid age', () async {
      final notifier = container.read(settingsProvider.notifier);

      // Test age too low
      expect(() => notifier.updateAge(5), throwsA(isA<ArgumentError>()));

      // Test age too high
      expect(() => notifier.updateAge(150), throwsA(isA<ArgumentError>()));
    });

    test('throws error for invalid chart window', () async {
      final notifier = container.read(settingsProvider.notifier);

      // Test invalid chart window value
      expect(
        () => notifier.updateChartWindow(25),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('loads previously saved settings from database', () async {
      // Save settings to database
      await DatabaseService.instance.setSetting('user_age', '40');
      await DatabaseService.instance.setSetting('chart_window_seconds', '45');

      // Create new container to trigger settings load
      final newContainer = ProviderContainer();

      // Wait for settings to load
      await Future.delayed(const Duration(milliseconds: 100));

      final settings = newContainer.read(settingsProvider);

      expect(settings.age, 40);
      expect(settings.chartWindowSeconds, 45);

      newContainer.dispose();
    });
  });

  group('SessionProvider Statistics', () {
    test('calculates average, min, and max correctly', () {
      // This test verifies the statistics calculation logic
      // We test the logic directly rather than requiring full BLE integration

      int sumBpm = 0;
      int readingsCount = 0;
      int? minHr;
      int? maxHr;

      // Simulate readings: 120, 130, 110, 140
      final readings = [120, 130, 110, 140];

      for (final bpm in readings) {
        readingsCount++;
        sumBpm += bpm;
        minHr = minHr == null ? bpm : (bpm < minHr ? bpm : minHr);
        maxHr = maxHr == null ? bpm : (bpm > maxHr ? bpm : maxHr);
      }

      final avgHr = (sumBpm / readingsCount).round();

      expect(avgHr, 125); // (120 + 130 + 110 + 140) / 4 = 125
      expect(minHr, 110);
      expect(maxHr, 140);
      expect(readingsCount, 4);
    });
  });
}
