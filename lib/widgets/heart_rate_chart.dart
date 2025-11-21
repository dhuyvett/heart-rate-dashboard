import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/heart_rate_reading.dart';

/// A real-time line chart displaying heart rate data over time.
///
/// This widget uses fl_chart to render a scrolling line chart that shows
/// the heart rate readings within a specified time window. The chart
/// automatically updates as new data arrives and scrolls to show the
/// most recent readings.
class HeartRateChart extends StatelessWidget {
  /// The heart rate readings to display.
  /// Should be sorted by timestamp (oldest to newest).
  final List<HeartRateReading> readings;

  /// The time window in seconds to display on the chart.
  /// Only readings within this window from the current time are shown.
  final int windowSeconds;

  /// The color to use for the chart line.
  /// Typically matches the current heart rate zone color.
  final Color lineColor;

  /// Creates a heart rate chart widget.
  const HeartRateChart({
    required this.readings,
    required this.windowSeconds,
    required this.lineColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Handle empty data state
    if (readings.isEmpty) {
      return Center(
        child: Text(
          'Waiting for heart rate data...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    // Filter readings to show only those within the time window
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(seconds: windowSeconds));
    final visibleReadings = readings
        .where((r) => r.timestamp.isAfter(windowStart))
        .toList();

    if (visibleReadings.isEmpty) {
      return Center(
        child: Text(
          'No recent data',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    // Convert readings to chart spots
    final spots = _createSpots(visibleReadings, windowStart);

    // Calculate Y-axis bounds
    final allBpm = visibleReadings.map((r) => r.bpm).toList();
    final minBpm = allBpm.reduce((a, b) => a < b ? a : b);
    final maxBpm = allBpm.reduce((a, b) => a > b ? a : b);

    // Add padding to Y-axis range
    final yMin = (minBpm - 10).clamp(30, 250).toDouble();
    final yMax = (maxBpm + 10).clamp(30, 250).toDouble();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          minY: yMin,
          maxY: yMax,
          minX: 0,
          maxX: windowSeconds.toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
            verticalInterval: windowSeconds / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: theme.textTheme.bodySmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: windowSeconds / 4,
                getTitlesWidget: (value, meta) {
                  final seconds = windowSeconds - value.toInt();
                  return Text('${seconds}s', style: theme.textTheme.bodySmall);
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Converts heart rate readings to chart spots.
  ///
  /// X-axis values are seconds from the start of the window (0 to windowSeconds).
  /// Y-axis values are BPM values.
  List<FlSpot> _createSpots(
    List<HeartRateReading> readings,
    DateTime windowStart,
  ) {
    return readings.map((reading) {
      // Calculate X position (seconds from window start)
      final xSeconds = reading.timestamp.difference(windowStart).inSeconds;

      return FlSpot(xSeconds.toDouble(), reading.bpm.toDouble());
    }).toList();
  }
}
