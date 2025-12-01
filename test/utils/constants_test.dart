// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/utils/constants.dart';

void main() {
  group('Constants', () {
    test('default values are within expected bounds', () {
      expect(defaultAge, inInclusiveRange(10, 100));
      expect(defaultChartWindowSeconds, anyOf(15, 30, 45, 60));
      expect(demoModeDeviceName, isNotEmpty);
      expect(maxReconnectionAttempts, greaterThan(0));
    });
  });
}
