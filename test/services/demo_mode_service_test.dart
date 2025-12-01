// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/services/demo_mode_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DemoModeService', () {
    late DemoModeService service;

    setUp(() {
      service = DemoModeService.instance;
      service.reset(); // Reset to clean state before each test
    });

    tearDown(() {
      service.stopDemoMode();
    });

    test('should start and stop demo mode correctly', () async {
      // Initially not active
      expect(service.isActive, isFalse);

      // Start demo mode
      service.startDemoMode();
      expect(service.isActive, isTrue);

      // Stop demo mode
      service.stopDemoMode();
      expect(service.isActive, isFalse);
    });

    test('should generate BPM values within valid range (60-180)', () async {
      service.startDemoMode();

      final stream = service.getDemoModeStream();

      // Collect first 3 values with an explicit timeout
      final values = await stream
          .take(3)
          .timeout(const Duration(seconds: 5))
          .toList();

      service.stopDemoMode();

      expect(values, isNotEmpty);
      for (final bpm in values) {
        expect(bpm, greaterThanOrEqualTo(60));
        expect(bpm, lessThanOrEqualTo(180));
      }
    });

    test('should emit values at approximately 1.5 second intervals', () async {
      service.startDemoMode();

      final stream = service.getDemoModeStream();
      final timestamps = await stream
          .map((_) => DateTime.now())
          .take(3)
          .timeout(const Duration(seconds: 6))
          .toList();

      service.stopDemoMode();

      expect(timestamps.length, greaterThanOrEqualTo(2));

      // Calculate intervals between values
      final intervals = <int>[];
      for (var i = 1; i < timestamps.length; i++) {
        final interval = timestamps[i]
            .difference(timestamps[i - 1])
            .inMilliseconds;
        intervals.add(interval);
      }

      // Average interval should be around 1500ms (with some tolerance)
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      expect(avgInterval, greaterThan(1200)); // At least 1.2 seconds
      expect(avgInterval, lessThan(1800)); // At most 1.8 seconds
    });

    test(
      'should generate realistic variability between consecutive values',
      () async {
        service.startDemoMode();

        final stream = service.getDemoModeStream();
        final values = await stream
            .take(4)
            .timeout(const Duration(seconds: 6))
            .toList();

        service.stopDemoMode();

        expect(values.length, greaterThanOrEqualTo(2));

        // Calculate differences between consecutive values
        final differences = <int>[];
        for (var i = 1; i < values.length; i++) {
          differences.add((values[i] - values[i - 1]).abs());
        }

        // Most differences should be small (realistic variability)
        // Allow for some larger jumps during trend changes
        final smallDifferences = differences.where((d) => d <= 15).length;
        expect(smallDifferences / differences.length, greaterThan(0.5));
      },
    );

    test('should throw error when getting stream before starting', () {
      expect(() => service.getDemoModeStream(), throwsA(isA<StateError>()));
    });
  });
}
