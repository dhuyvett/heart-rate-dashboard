import '../utils/constants.dart';

/// Represents the application settings for the Heart Rate Dashboard.
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

  /// Whether to keep the screen awake while monitoring heart rate.
  /// When enabled, the screen will not turn off on the monitoring screen.
  final bool keepScreenAwake;

  /// Whether dark mode is enabled.
  /// When enabled, the app uses a dark color scheme.
  final bool darkMode;

  /// Creates an app settings instance.
  ///
  /// Defaults to [defaultAge] and [defaultChartWindowSeconds] if not specified.
  const AppSettings({
    this.age = defaultAge,
    this.chartWindowSeconds = defaultChartWindowSeconds,
    this.keepScreenAwake = false,
    this.darkMode = false,
  });

  /// Creates a copy of this settings with updated fields.
  AppSettings copyWith({
    int? age,
    int? chartWindowSeconds,
    bool? keepScreenAwake,
    bool? darkMode,
  }) {
    return AppSettings(
      age: age ?? this.age,
      chartWindowSeconds: chartWindowSeconds ?? this.chartWindowSeconds,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppSettings &&
        other.age == age &&
        other.chartWindowSeconds == chartWindowSeconds &&
        other.keepScreenAwake == keepScreenAwake &&
        other.darkMode == darkMode;
  }

  @override
  int get hashCode =>
      Object.hash(age, chartWindowSeconds, keepScreenAwake, darkMode);

  @override
  String toString() {
    return 'AppSettings(age: $age, chartWindowSeconds: $chartWindowSeconds, '
        'keepScreenAwake: $keepScreenAwake, darkMode: $darkMode)';
  }
}
