/// Represents the different heart rate training zones based on percentage of maximum heart rate.
///
/// Zones are calculated using the Hopkins Medicine methodology:
/// - Maximum HR = 220 - age
/// - Each zone represents a percentage range of max HR
///
/// Zone colors are defined in theme_colors.dart and used for visual feedback.
enum HeartRateZone {
  /// Resting heart rate zone (below 50% of max HR).
  /// Typically experienced during rest or very light activity.
  /// Display color: Blue
  resting,

  /// Zone 1: Very Light intensity (50-60% of max HR).
  /// Light activity, warm-up, or cool-down intensity.
  /// Display color: Light Blue
  zone1,

  /// Zone 2: Light intensity (60-70% of max HR).
  /// Fat burning zone, endurance base building.
  /// Display color: Green
  zone2,

  /// Zone 3: Moderate intensity (70-80% of max HR).
  /// Aerobic fitness, cardiovascular improvement.
  /// Display color: Yellow
  zone3,

  /// Zone 4: Hard/Vigorous intensity (80-90% of max HR).
  /// Anaerobic threshold, performance improvement.
  /// Display color: Orange
  zone4,

  /// Zone 5: Maximum effort (90-100% of max HR).
  /// Maximum effort, short bursts only.
  /// Display color: Red
  zone5,
}
