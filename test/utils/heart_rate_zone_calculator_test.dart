import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/heart_rate_zone.dart';
import 'package:heart_rate_dashboard/models/sex.dart';
import 'package:heart_rate_dashboard/utils/heart_rate_zone_calculator.dart';
import 'package:heart_rate_dashboard/utils/theme_colors.dart';

void main() {
  group('HeartRateZoneCalculator', () {
    test('calculateMaxHeartRate returns sex-specific values', () {
      // Male: 214 - (0.8 × age)
      expect(
        HeartRateZoneCalculator.calculateMaxHeartRateBySex(30, Sex.male),
        equals(190),
      );
      expect(
        HeartRateZoneCalculator.calculateMaxHeartRateBySex(25, Sex.male),
        equals(194),
      );
      expect(
        HeartRateZoneCalculator.calculateMaxHeartRateBySex(50, Sex.male),
        equals(174),
      );

      // Female: 209 - (0.9 × age)
      expect(
        HeartRateZoneCalculator.calculateMaxHeartRateBySex(30, Sex.female),
        equals(182),
      );
      expect(
        HeartRateZoneCalculator.calculateMaxHeartRateBySex(25, Sex.female),
        equals(187),
      );
      expect(
        HeartRateZoneCalculator.calculateMaxHeartRateBySex(50, Sex.female),
        equals(164),
      );
    });

    test('getZoneForBpm returns correct zone for various BPM values', () {
      // For a 30-year-old male: Max HR = 190
      // Resting: <95, Zone1: 95-114, Zone2: 114-133, Zone3: 133-152, Zone4: 152-171, Zone5: 171-190
      const age = 30;

      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(80, age, Sex.male),
        equals(HeartRateZone.resting),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(100, age, Sex.male),
        equals(HeartRateZone.zone1),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(120, age, Sex.male),
        equals(HeartRateZone.zone2),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(140, age, Sex.male),
        equals(HeartRateZone.zone3),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(160, age, Sex.male),
        equals(HeartRateZone.zone4),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(180, age, Sex.male),
        equals(HeartRateZone.zone5),
      );
    });

    test('getZoneForBpm handles boundary values correctly', () {
      const age = 30;
      const sex = Sex.male;
      // Max HR = 190 (male)
      // Zone boundaries: 95, 114, 133, 152, 171, 190

      // Test exact boundaries (lower boundaries should be in that zone)
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(95, age, sex),
        equals(HeartRateZone.zone1),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(114, age, sex),
        equals(HeartRateZone.zone2),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(133, age, sex),
        equals(HeartRateZone.zone3),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(152, age, sex),
        equals(HeartRateZone.zone4),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(171, age, sex),
        equals(HeartRateZone.zone5),
      );

      // Test one BPM below boundaries
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(94, age, sex),
        equals(HeartRateZone.resting),
      );
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(113, age, sex),
        equals(HeartRateZone.zone1),
      );

      // Test HR above max (should still be zone5)
      expect(
        HeartRateZoneCalculator.getZoneForBpmBySex(200, age, sex),
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
      final ranges = HeartRateZoneCalculator.getZoneRangesBySex(age, Sex.male);

      // Max HR = 190 (male)
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
