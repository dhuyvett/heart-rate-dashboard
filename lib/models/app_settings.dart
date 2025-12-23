import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import 'max_hr_calculation_method.dart';
import 'session_statistic.dart';
import 'sex.dart';

/// Represents the application settings for the Heart Rate Dashboard.
///
/// Settings include user age for heart rate zone calculations and
/// the chart time window for the real-time line chart display.
class AppSettings {
  /// User's age in years, used to calculate maximum heart rate and zones.
  /// Valid range: 10-100 years.
  final int age;

  /// User's biological sex for more accurate heart rate calculations.
  final Sex sex;

  /// Method for calculating maximum heart rate.
  final MaxHRCalculationMethod maxHRCalculationMethod;

  /// Custom maximum heart rate value (used when maxHRCalculationMethod is custom).
  /// Valid range: 100-220 BPM.
  final int? customMaxHR;

  /// Time window in seconds for the real-time heart rate chart.
  /// Determines how many seconds of historical data to display.
  final int chartWindowSeconds;

  /// Whether to keep the screen awake while monitoring heart rate.
  /// When enabled, the screen will not turn off on the monitoring screen.
  final bool keepScreenAwake;

  /// Whether dark mode is enabled.
  /// When enabled, the app uses a dark color scheme.
  final bool darkMode;

  /// Session retention period in days.
  /// Sessions older than this will be automatically deleted.
  /// Valid range: 1-3650 days (approximately 10 years).
  /// Default: 30 days.
  final int sessionRetentionDays;

  /// Which statistics should be shown on the monitoring screen.
  /// Defaults to all available stats.
  final List<SessionStatistic> visibleSessionStats;

  /// Whether to display speed/distance in miles instead of kilometers.
  final bool useMiles;

  /// Creates an app settings instance.
  ///
  /// Defaults to [defaultAge] and [defaultChartWindowSeconds] if not specified.
  const AppSettings({
    this.age = defaultAge,
    this.sex = Sex.male,
    this.maxHRCalculationMethod = MaxHRCalculationMethod.foxFormula,
    this.customMaxHR,
    this.chartWindowSeconds = defaultChartWindowSeconds,
    this.keepScreenAwake = false,
    this.darkMode = false,
    this.sessionRetentionDays = 30,
    this.visibleSessionStats = defaultSessionStatistics,
    this.useMiles = false,
  });

  /// Creates a copy of this settings with updated fields.
  AppSettings copyWith({
    int? age,
    Sex? sex,
    MaxHRCalculationMethod? maxHRCalculationMethod,
    int? customMaxHR,
    int? chartWindowSeconds,
    bool? keepScreenAwake,
    bool? darkMode,
    int? sessionRetentionDays,
    List<SessionStatistic>? visibleSessionStats,
    bool? useMiles,
  }) {
    return AppSettings(
      age: age ?? this.age,
      sex: sex ?? this.sex,
      maxHRCalculationMethod:
          maxHRCalculationMethod ?? this.maxHRCalculationMethod,
      customMaxHR: customMaxHR ?? this.customMaxHR,
      chartWindowSeconds: chartWindowSeconds ?? this.chartWindowSeconds,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      darkMode: darkMode ?? this.darkMode,
      sessionRetentionDays: sessionRetentionDays ?? this.sessionRetentionDays,
      visibleSessionStats: visibleSessionStats ?? this.visibleSessionStats,
      useMiles: useMiles ?? this.useMiles,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppSettings &&
        other.age == age &&
        other.sex == sex &&
        other.maxHRCalculationMethod == maxHRCalculationMethod &&
        other.customMaxHR == customMaxHR &&
        other.chartWindowSeconds == chartWindowSeconds &&
        other.keepScreenAwake == keepScreenAwake &&
        other.darkMode == darkMode &&
        other.sessionRetentionDays == sessionRetentionDays &&
        listEquals(other.visibleSessionStats, visibleSessionStats) &&
        other.useMiles == useMiles;
  }

  @override
  int get hashCode => Object.hash(
    age,
    sex,
    maxHRCalculationMethod,
    customMaxHR,
    chartWindowSeconds,
    keepScreenAwake,
    darkMode,
    sessionRetentionDays,
    Object.hashAll(visibleSessionStats),
    useMiles,
  );

  @override
  String toString() {
    return 'AppSettings(age: $age, sex: $sex, '
        'maxHRCalculationMethod: $maxHRCalculationMethod, '
        'customMaxHR: $customMaxHR, '
        'chartWindowSeconds: $chartWindowSeconds, '
        'keepScreenAwake: $keepScreenAwake, darkMode: $darkMode, '
        'sessionRetentionDays: $sessionRetentionDays, '
        'visibleSessionStats: $visibleSessionStats, useMiles: $useMiles)';
  }
}
