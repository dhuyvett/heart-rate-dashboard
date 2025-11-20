import 'package:flutter/material.dart';
import '../models/heart_rate_zone.dart';

/// Theme colors for heart rate zones.
///
/// These colors provide visual feedback for different heart rate intensity zones
/// following the Hopkins Medicine heart rate zone methodology.
class ZoneColors {
  /// Private constructor to prevent instantiation.
  ZoneColors._();

  /// Resting zone color (below 50% max HR).
  /// Blue indicates low intensity or resting state.
  static const Color resting = Colors.blue;

  /// Zone 1 color (50-60% max HR).
  /// Light blue indicates very light activity.
  static const Color zone1 = Colors.lightBlue;

  /// Zone 2 color (60-70% max HR).
  /// Green indicates light intensity, fat-burning zone.
  static const Color zone2 = Colors.green;

  /// Zone 3 color (70-80% max HR).
  /// Yellow indicates moderate intensity, aerobic zone.
  static const Color zone3 = Colors.yellow;

  /// Zone 4 color (80-90% max HR).
  /// Orange indicates hard/vigorous intensity.
  static const Color zone4 = Colors.orange;

  /// Zone 5 color (90-100% max HR).
  /// Red indicates maximum effort.
  static const Color zone5 = Colors.red;

  /// Returns the color associated with a given heart rate zone.
  ///
  /// This method maps each [HeartRateZone] enum value to its corresponding color,
  /// providing consistent color coding throughout the application.
  static Color getColorForZone(HeartRateZone zone) {
    switch (zone) {
      case HeartRateZone.resting:
        return resting;
      case HeartRateZone.zone1:
        return zone1;
      case HeartRateZone.zone2:
        return zone2;
      case HeartRateZone.zone3:
        return zone3;
      case HeartRateZone.zone4:
        return zone4;
      case HeartRateZone.zone5:
        return zone5;
    }
  }
}
