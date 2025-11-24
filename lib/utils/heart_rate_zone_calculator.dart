import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/gender.dart';
import '../models/heart_rate_zone.dart';
import '../models/max_hr_calculation_method.dart';
import 'theme_colors.dart';

/// Utility class for calculating heart rate zones using the Hopkins Medicine methodology.
///
/// This class provides methods to:
/// - Calculate maximum heart rate based on age and calculation method
/// - Determine the heart rate zone for a given BPM
/// - Get color coding for zones
/// - Calculate zone BPM ranges for a specific age
/// - Provide user-friendly zone labels
class HeartRateZoneCalculator {
  /// Private constructor to prevent instantiation.
  HeartRateZoneCalculator._();

  /// Calculates maximum heart rate using settings.
  ///
  /// Supports multiple calculation methods:
  /// - Fox Formula: 220 - age (for both men and women)
  /// - Custom: User-defined value
  ///
  /// Example:
  /// ```dart
  /// final maxHr = HeartRateZoneCalculator.calculateMaxHeartRate(settings);
  /// ```
  static int calculateMaxHeartRate(AppSettings settings) {
    switch (settings.maxHRCalculationMethod) {
      case MaxHRCalculationMethod.foxFormula:
        return 220 - settings.age;
      case MaxHRCalculationMethod.huntFormula:
        return (211 - (0.64 * settings.age)).round();
      case MaxHRCalculationMethod.tanakaFormula:
        return (208 - (0.7 * settings.age)).round();
      case MaxHRCalculationMethod.shargalFormula:
        if (settings.gender == Gender.female) {
          return (209.273 - (0.804 * settings.age)).round();
        } else {
          return (208.609 - (0.71 * settings.age)).round();
        }
      case MaxHRCalculationMethod.custom:
        return settings.customMaxHR ?? 190; // Fallback to 190 if not set
    }
  }

  /// Calculates maximum heart rate using gender-specific formulas (legacy).
  ///
  /// Uses more accurate gender-specific formulas:
  /// - Male: 214 - (0.8 × age)
  /// - Female: 209 - (0.9 × age)
  ///
  /// [age] should be between 10-100 for realistic results.
  /// [gender] determines which formula to use.
  ///
  /// Example:
  /// ```dart
  /// final maxHr = HeartRateZoneCalculator.calculateMaxHeartRateByGender(30, Gender.male); // Returns 190
  /// ```
  static int calculateMaxHeartRateByGender(int age, Gender gender) {
    if (gender == Gender.female) {
      return (209 - (0.9 * age)).round();
    } else {
      return (214 - (0.8 * age)).round();
    }
  }

  /// Determines the heart rate zone for a given BPM using settings.
  ///
  /// Uses Hopkins Medicine zone methodology:
  /// - Resting: Below 50% of max HR
  /// - Zone 1: 50-60% of max HR (Very Light)
  /// - Zone 2: 60-70% of max HR (Light)
  /// - Zone 3: 70-80% of max HR (Moderate)
  /// - Zone 4: 80-90% of max HR (Hard)
  /// - Zone 5: 90-100% of max HR (Maximum)
  ///
  /// Example:
  /// ```dart
  /// final zone = HeartRateZoneCalculator.getZoneForBpm(140, settings);
  /// ```
  static HeartRateZone getZoneForBpm(int bpm, AppSettings settings) {
    final maxHr = calculateMaxHeartRate(settings);

    // Calculate zone boundaries
    final zone1Threshold = (maxHr * 0.50).round();
    final zone2Threshold = (maxHr * 0.60).round();
    final zone3Threshold = (maxHr * 0.70).round();
    final zone4Threshold = (maxHr * 0.80).round();
    final zone5Threshold = (maxHr * 0.90).round();

    // Determine zone based on BPM
    if (bpm < zone1Threshold) {
      return HeartRateZone.resting;
    } else if (bpm < zone2Threshold) {
      return HeartRateZone.zone1;
    } else if (bpm < zone3Threshold) {
      return HeartRateZone.zone2;
    } else if (bpm < zone4Threshold) {
      return HeartRateZone.zone3;
    } else if (bpm < zone5Threshold) {
      return HeartRateZone.zone4;
    } else {
      return HeartRateZone.zone5;
    }
  }

  /// Determines the heart rate zone for a given BPM, age, and gender (legacy).
  ///
  /// Uses Hopkins Medicine zone methodology:
  /// - Resting: Below 50% of max HR
  /// - Zone 1: 50-60% of max HR (Very Light)
  /// - Zone 2: 60-70% of max HR (Light)
  /// - Zone 3: 70-80% of max HR (Moderate)
  /// - Zone 4: 80-90% of max HR (Hard)
  /// - Zone 5: 90-100% of max HR (Maximum)
  ///
  /// Example:
  /// ```dart
  /// final zone = HeartRateZoneCalculator.getZoneForBpmByGender(140, 30, Gender.male); // Returns HeartRateZone.zone3
  /// ```
  static HeartRateZone getZoneForBpmByGender(int bpm, int age, Gender gender) {
    final maxHr = calculateMaxHeartRateByGender(age, gender);

    // Calculate zone boundaries
    final zone1Threshold = (maxHr * 0.50).round();
    final zone2Threshold = (maxHr * 0.60).round();
    final zone3Threshold = (maxHr * 0.70).round();
    final zone4Threshold = (maxHr * 0.80).round();
    final zone5Threshold = (maxHr * 0.90).round();

    // Determine zone based on BPM
    if (bpm < zone1Threshold) {
      return HeartRateZone.resting;
    } else if (bpm < zone2Threshold) {
      return HeartRateZone.zone1;
    } else if (bpm < zone3Threshold) {
      return HeartRateZone.zone2;
    } else if (bpm < zone4Threshold) {
      return HeartRateZone.zone3;
    } else if (bpm < zone5Threshold) {
      return HeartRateZone.zone4;
    } else {
      return HeartRateZone.zone5;
    }
  }

  /// Returns the color associated with a given heart rate zone.
  ///
  /// Colors are defined in [ZoneColors] and follow the Hopkins Medicine color scheme:
  /// - Resting: Blue
  /// - Zone 1: Light Blue
  /// - Zone 2: Green
  /// - Zone 3: Yellow
  /// - Zone 4: Orange
  /// - Zone 5: Red
  ///
  /// Example:
  /// ```dart
  /// final color = HeartRateZoneCalculator.getColorForZone(HeartRateZone.zone3); // Returns Colors.yellow
  /// ```
  static Color getColorForZone(HeartRateZone zone) {
    return ZoneColors.getColorForZone(zone);
  }

  /// Returns the BPM ranges for all heart rate zones using settings.
  ///
  /// Returns a [Map] where each [HeartRateZone] maps to a tuple of (minBpm, maxBpm).
  ///
  /// Example:
  /// ```dart
  /// final ranges = HeartRateZoneCalculator.getZoneRanges(settings);
  /// ```
  static Map<HeartRateZone, (int, int)> getZoneRanges(AppSettings settings) {
    final maxHr = calculateMaxHeartRate(settings);

    // Calculate zone boundaries
    final zone1Threshold = (maxHr * 0.50).round();
    final zone2Threshold = (maxHr * 0.60).round();
    final zone3Threshold = (maxHr * 0.70).round();
    final zone4Threshold = (maxHr * 0.80).round();
    final zone5Threshold = (maxHr * 0.90).round();

    return {
      HeartRateZone.resting: (0, zone1Threshold - 1),
      HeartRateZone.zone1: (zone1Threshold, zone2Threshold - 1),
      HeartRateZone.zone2: (zone2Threshold, zone3Threshold - 1),
      HeartRateZone.zone3: (zone3Threshold, zone4Threshold - 1),
      HeartRateZone.zone4: (zone4Threshold, zone5Threshold - 1),
      HeartRateZone.zone5: (zone5Threshold, maxHr),
    };
  }

  /// Returns the BPM ranges for all heart rate zones for a given age and gender (legacy).
  ///
  /// Returns a [Map] where each [HeartRateZone] maps to a tuple of (minBpm, maxBpm).
  ///
  /// Example for age 30, male (max HR = 190):
  /// ```dart
  /// final ranges = HeartRateZoneCalculator.getZoneRangesByGender(30, Gender.male);
  /// // Returns:
  /// // {
  /// //   HeartRateZone.resting: (0, 94),
  /// //   HeartRateZone.zone1: (95, 113),
  /// //   HeartRateZone.zone2: (114, 132),
  /// //   HeartRateZone.zone3: (133, 151),
  /// //   HeartRateZone.zone4: (152, 170),
  /// //   HeartRateZone.zone5: (171, 190),
  /// // }
  /// ```
  static Map<HeartRateZone, (int, int)> getZoneRangesByGender(
    int age,
    Gender gender,
  ) {
    final maxHr = calculateMaxHeartRateByGender(age, gender);

    // Calculate zone boundaries
    final zone1Threshold = (maxHr * 0.50).round();
    final zone2Threshold = (maxHr * 0.60).round();
    final zone3Threshold = (maxHr * 0.70).round();
    final zone4Threshold = (maxHr * 0.80).round();
    final zone5Threshold = (maxHr * 0.90).round();

    return {
      HeartRateZone.resting: (0, zone1Threshold - 1),
      HeartRateZone.zone1: (zone1Threshold, zone2Threshold - 1),
      HeartRateZone.zone2: (zone2Threshold, zone3Threshold - 1),
      HeartRateZone.zone3: (zone3Threshold, zone4Threshold - 1),
      HeartRateZone.zone4: (zone4Threshold, zone5Threshold - 1),
      HeartRateZone.zone5: (zone5Threshold, maxHr),
    };
  }

  /// Returns a user-friendly label for a heart rate zone.
  ///
  /// Labels include both the zone number and the intensity description.
  ///
  /// Example:
  /// ```dart
  /// final label = HeartRateZoneCalculator.getZoneLabel(HeartRateZone.zone3); // Returns "Zone 3 - Moderate"
  /// ```
  static String getZoneLabel(HeartRateZone zone) {
    switch (zone) {
      case HeartRateZone.resting:
        return 'Resting';
      case HeartRateZone.zone1:
        return 'Zone 1 - Very Light';
      case HeartRateZone.zone2:
        return 'Zone 2 - Light';
      case HeartRateZone.zone3:
        return 'Zone 3 - Moderate';
      case HeartRateZone.zone4:
        return 'Zone 4 - Hard';
      case HeartRateZone.zone5:
        return 'Zone 5 - Maximum';
    }
  }

  /// Returns the percentage range for a heart rate zone as a string.
  ///
  /// Useful for displaying zone information to users.
  ///
  /// Example:
  /// ```dart
  /// final percentage = HeartRateZoneCalculator.getZonePercentageRange(HeartRateZone.zone3); // Returns "70-80%"
  /// ```
  static String getZonePercentageRange(HeartRateZone zone) {
    switch (zone) {
      case HeartRateZone.resting:
        return '<50%';
      case HeartRateZone.zone1:
        return '50-60%';
      case HeartRateZone.zone2:
        return '60-70%';
      case HeartRateZone.zone3:
        return '70-80%';
      case HeartRateZone.zone4:
        return '80-90%';
      case HeartRateZone.zone5:
        return '90-100%';
    }
  }
}
