import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/heart_rate_zone.dart';
import 'package:heart_rate_dashboard/utils/heart_rate_zone_calculator.dart';
import 'package:heart_rate_dashboard/utils/theme_colors.dart';

void main() {
  group('HeartRateZoneCalculator', () {
    test('calculateMaxHeartRate returns 220 minus age', () {
      expect(HeartRateZoneCalculator.calculateMaxHeartRate(30), equals(190));
      expect(HeartRateZoneCalculator.calculateMaxHeartRate(25), equals(195));
      expect(HeartRateZoneCalculator.calculateMaxHeartRate(50), equals(170));
    });

    test('getZoneForBpm returns correct zone for various BPM values', () {
      // For a 30-year-old: Max HR = 190
      // Resting: <95, Zone1: 95-114, Zone2: 114-133, Zone3: 133-152, Zone4: 152-171, Zone5: 171-190
      const age = 30;

      expect(
        HeartRateZoneCalculator.getZoneForBpm(80, age),
        equals(HeartRateZone.resting),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpm(100, age),
        equals(HeartRateZone.zone1),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpm(120, age),
        equals(HeartRateZone.zone2),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpm(140, age),
        equals(HeartRateZone.zone3),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpm(160, age),
        equals(HeartRateZone.zone4),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpm(180, age),
        equals(HeartRateZone.zone5),
      );
    });

    test('getZoneForBpm handles boundary values correctly', () {
      const age = 30;
      // Max HR = 190
      // Zone boundaries: 95, 114, 133, 152, 171, 190

      // Test exact boundaries (lower boundaries should be in that zone)
      expect(
        HeartRateZoneCalculator.getZoneForBpm(95, age),
        equals(HeartRateZone.zone1),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpm(114, age),
        equals(HeartRateZone.zone2),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpm(133, age),
        equals(HeartRateZone.zone3),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpm(152, age),
        equals(HeartRateZone.zone4),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpm(171, age),
        equals(HeartRateZone.zone5),
      );

      // Test one BPM below boundaries
      expect(
        HeartRateZoneCalculator.getZoneForBpm(94, age),
        equals(HeartRateZone.resting),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpm(113, age),
        equals(HeartRateZone.zone1),
      );

      // Test HR above max (should still be zone5)
      expect(
        HeartRateZoneCalculator.getZoneForBpm(200, age),
        equals(HeartRateZone.zone5),
      );
    });

    test('getColorForZone returns correct color', () {
      expect(
        HeartRateZoneCalculator.getColorForZone(HeartRateZone.resting),
        equals(ZoneColors.resting),
      );
      expect(
        HeartRateZoneCalculator.getColorForZone(HeartRateZone.zone1),
        equals(ZoneColors.zone1),
      );
      expect(
        HeartRateZoneCalculator.getColorForZone(HeartRateZone.zone2),
        equals(ZoneColors.zone2),
      );
      expect(
        HeartRateZoneCalculator.getColorForZone(HeartRateZone.zone3),
        equals(ZoneColors.zone3),
      );
      expect(
        HeartRateZoneCalculator.getColorForZone(HeartRateZone.zone4),
        equals(ZoneColors.zone4),
      );
      expect(
        HeartRateZoneCalculator.getColorForZone(HeartRateZone.zone5),
        equals(ZoneColors.zone5),
      );
    });

    test('getZoneRanges returns correct BPM ranges for given age', () {
      const age = 30;
      final ranges = HeartRateZoneCalculator.getZoneRanges(age);

      // Max HR = 190
      // Resting: <95, Zone1: 95-114, Zone2: 114-133, Zone3: 133-152, Zone4: 152-171, Zone5: 171-190
      expect(ranges[HeartRateZone.resting], equals((0, 94)));
      expect(ranges[HeartRateZone.zone1], equals((95, 113)));
      expect(ranges[HeartRateZone.zone2], equals((114, 132)));
      expect(ranges[HeartRateZone.zone3], equals((133, 151)));
      expect(ranges[HeartRateZone.zone4], equals((152, 170)));
      expect(ranges[HeartRateZone.zone5], equals((171, 190)));
    });

    test('getZoneLabel returns user-friendly labels', () {
      expect(
        HeartRateZoneCalculator.getZoneLabel(HeartRateZone.resting),
        equals('Resting'),
      );
      expect(
        HeartRateZoneCalculator.getZoneLabel(HeartRateZone.zone1),
        equals('Zone 1 - Very Light'),
      );
      expect(
        HeartRateZoneCalculator.getZoneLabel(HeartRateZone.zone2),
        equals('Zone 2 - Light'),
      );
      expect(
        HeartRateZoneCalculator.getZoneLabel(HeartRateZone.zone3),
        equals('Zone 3 - Moderate'),
      );
      expect(
        HeartRateZoneCalculator.getZoneLabel(HeartRateZone.zone4),
        equals('Zone 4 - Hard'),
      );
      expect(
        HeartRateZoneCalculator.getZoneLabel(HeartRateZone.zone5),
        equals('Zone 5 - Maximum'),
      );
    });

    test('getZonePercentageRange returns correct percentage strings', () {
      expect(
        HeartRateZoneCalculator.getZonePercentageRange(HeartRateZone.resting),
        equals('<50%'),
      );
      expect(
        HeartRateZoneCalculator.getZonePercentageRange(HeartRateZone.zone1),
        equals('50-60%'),
      );
      expect(
        HeartRateZoneCalculator.getZonePercentageRange(HeartRateZone.zone2),
        equals('60-70%'),
      );
      expect(
        HeartRateZoneCalculator.getZonePercentageRange(HeartRateZone.zone3),
        equals('70-80%'),
      );
      expect(
        HeartRateZoneCalculator.getZonePercentageRange(HeartRateZone.zone4),
        equals('80-90%'),
      );
      expect(
        HeartRateZoneCalculator.getZonePercentageRange(HeartRateZone.zone5),
        equals('90-100%'),
      );
    });
  });
}
