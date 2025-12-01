// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/models/heart_rate_zone.dart';
import 'package:heart_rate_dashboard/models/max_hr_calculation_method.dart';
import 'package:heart_rate_dashboard/models/sex.dart';
import 'package:heart_rate_dashboard/models/app_settings.dart';
import 'package:heart_rate_dashboard/utils/heart_rate_zone_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HeartRateZoneCalculator', () {
    test('calculates max HR using fox by default', () {
      final settings = const AppSettings(age: 30);
      expect(
        HeartRateZoneCalculator.calculateMaxHeartRate(settings),
        190, // 220 - age
      );
    });

    test('calculates max HR using tanaka formula', () {
      final settings = const AppSettings(
        age: 40,
        maxHRCalculationMethod: MaxHRCalculationMethod.tanakaFormula,
      );
      expect(
        HeartRateZoneCalculator.calculateMaxHeartRate(settings),
        180, // 208 - 0.7*40 = 180
      );
    });

    test('calculates max HR using shargal sex-specific formula', () {
      final femaleSettings = const AppSettings(
        age: 35,
        sex: Sex.female,
        maxHRCalculationMethod: MaxHRCalculationMethod.shargalFormula,
      );
      final maleSettings = const AppSettings(
        age: 35,
        sex: Sex.male,
        maxHRCalculationMethod: MaxHRCalculationMethod.shargalFormula,
      );

      expect(
        HeartRateZoneCalculator.calculateMaxHeartRate(femaleSettings),
        181, // 209.273 - 0.804*35 ≈ 181.133
      );
      expect(
        HeartRateZoneCalculator.calculateMaxHeartRate(maleSettings),
        184, // 208.609 - 0.71*35 ≈ 183.859
      );
    });

    test('uses custom max HR when provided', () {
      final settings = const AppSettings(
        age: 28,
        customMaxHR: 195,
        maxHRCalculationMethod: MaxHRCalculationMethod.custom,
      );

      expect(HeartRateZoneCalculator.calculateMaxHeartRate(settings), 195);
    });

    test('provides zone ranges and colors', () {
      final settings = const AppSettings(age: 30);
      final ranges = HeartRateZoneCalculator.getZoneRanges(settings);

      expect(ranges[HeartRateZone.resting], isNotNull);
      expect(ranges[HeartRateZone.zone5], isNotNull);

      final color = HeartRateZoneCalculator.getColorForZone(
        HeartRateZone.zone3,
      );
      expect(color, isA<Color>());

      final label = HeartRateZoneCalculator.getZoneLabel(HeartRateZone.zone4);
      expect(label, contains('Zone 4'));

      final pct = HeartRateZoneCalculator.getZonePercentageRange(
        HeartRateZone.zone2,
      );
      expect(pct, contains('%'));
    });
  });
}
