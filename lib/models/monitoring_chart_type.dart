/// Chart types available on the heart rate monitoring screen.
enum MonitoringChartType { heartRate, zoneTime }

extension MonitoringChartTypeLabels on MonitoringChartType {
  String get label {
    switch (this) {
      case MonitoringChartType.heartRate:
        return 'Heart Rate';
      case MonitoringChartType.zoneTime:
        return 'Zone Time';
    }
  }
}
