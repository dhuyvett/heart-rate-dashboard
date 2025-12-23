/// Available statistics that can be displayed on the monitoring screen.
enum SessionStatistic { duration, average, minimum, maximum, speed, distance }

/// Default set of statistics shown on the monitoring screen.
/// Speed and distance are opt-in.
const List<SessionStatistic> defaultSessionStatistics = [
  SessionStatistic.duration,
  SessionStatistic.average,
  SessionStatistic.minimum,
  SessionStatistic.maximum,
];
