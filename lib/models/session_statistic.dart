/// Available statistics that can be displayed on the monitoring screen.
enum SessionStatistic { duration, average, minimum, maximum }

/// Default set of statistics shown on the monitoring screen.
const List<SessionStatistic> defaultSessionStatistics = [
  SessionStatistic.duration,
  SessionStatistic.average,
  SessionStatistic.minimum,
  SessionStatistic.maximum,
];
