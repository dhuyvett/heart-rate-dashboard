// This file contains basic smoke tests for the Heart Rate Dashboard app.
//
// The original counter app smoke test was removed since the app has been
// completely restructured for heart rate monitoring functionality.
// See the test/screens/ and test/integration/ directories for comprehensive
// widget and integration tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/sex.dart';
import 'package:heart_rate_dashboard/models/scanned_device.dart';
import 'package:heart_rate_dashboard/models/heart_rate_zone.dart';
import 'package:heart_rate_dashboard/utils/heart_rate_zone_calculator.dart';

void main() {
  group('App Smoke Tests', () {
    test('ScannedDevice.demoMode() creates correct demo device', () {
      final demoDevice = ScannedDevice.demoMode();

      expect(demoDevice.isDemo, isTrue);
      expect(demoDevice.name, equals('Demo Mode'));
      expect(demoDevice.id, equals('DEMO_MODE_DEVICE'));
    });

    test('HeartRateZoneCalculator calculates max heart rate correctly', () {
      // Male: 214 - (0.8 × age)
      expect(
        HeartRateZoneCalculator.calculateMaxHeartRateBySex(30, Sex.male),
        equals(190),
      );
      expect(
        HeartRateZoneCalculator.calculateMaxHeartRateBySex(40, Sex.male),
        equals(182),
      );
      expect(
        HeartRateZoneCalculator.calculateMaxHeartRateBySex(50, Sex.male),
        equals(174),
      );
    });

    test('HeartRateZoneCalculator returns correct zones', () {
      // For age 30, male (max HR = 190):
      // - Resting: < 95 BPM (< 50%)
      // - Zone 1: 95-113 BPM (50-60%)
      // - Zone 2: 114-132 BPM (60-70%)
      // - Zone 3: 133-151 BPM (70-80%)
      // - Zone 4: 152-170 BPM (80-90%)
      // - Zone 5: 171+ BPM (90%+)

      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(80, 30, Sex.male),
        equals(HeartRateZone.resting),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(100, 30, Sex.male),
        equals(HeartRateZone.zone1),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(120, 30, Sex.male),
        equals(HeartRateZone.zone2),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(140, 30, Sex.male),
        equals(HeartRateZone.zone3),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(160, 30, Sex.male),
        equals(HeartRateZone.zone4),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(180, 30, Sex.male),
        equals(HeartRateZone.zone5),
      );
    });
  });
}
