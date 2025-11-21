import '../utils/constants.dart';

/// Represents the application settings for the workout tracker.
///
/// Settings include user age for heart rate zone calculations and
/// the chart time window for the real-time line chart display.
class AppSettings {
  /// User's age in years, used to calculate maximum heart rate and zones.
  /// Valid range: 10-100 years.
  final int age;

  /// Time window in seconds for the real-time heart rate chart.
  /// Determines how many seconds of historical data to display.
  final int chartWindowSeconds;

  /// Creates an app settings instance.
  ///
  /// Defaults to [defaultAge] and [defaultChartWindowSeconds] if not specified.
  const AppSettings({
    this.age = defaultAge,
    this.chartWindowSeconds = defaultChartWindowSeconds,
  });

  /// Creates a copy of this settings with updated fields.
  AppSettings copyWith({int? age, int? chartWindowSeconds}) {
    return AppSettings(
      age: age ?? this.age,
      chartWindowSeconds: chartWindowSeconds ?? this.chartWindowSeconds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppSettings &&
        other.age == age &&
        other.chartWindowSeconds == chartWindowSeconds;
  }

  @override
  int get hashCode => Object.hash(age, chartWindowSeconds);

  @override
  String toString() {
    return 'AppSettings(age: $age, chartWindowSeconds: $chartWindowSeconds)';
  }
}
