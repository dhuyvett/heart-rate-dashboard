import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/heart_rate_reading.dart';

/// A line chart displaying heart rate data over time.
///
/// This widget uses fl_chart to render heart rate data in two modes:
/// - Live mode: Shows real-time scrolling data with new data on the right
/// - Historical mode: Shows complete session data with oldest on left
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

  /// Optional resolver for per-reading zone colors.
  /// When provided, the chart will render segments per zone color.
  final Color Function(HeartRateReading reading)? zoneColorResolver;

  /// Optional opacity multiplier for zone colors (0.0 - 1.0).
  /// Useful for dimming the chart during pause/reconnect states.
  final double zoneColorOpacity;

  /// Optional reference time for the chart window.
  /// If provided, the chart will use this time instead of DateTime.now()
  /// for calculating the visible window. Useful for pausing the chart.
  final DateTime? referenceTime;

  /// Whether to display as a live scrolling chart (true) or historical chart (false).
  /// Live mode: New data appears on right, old data shifts left, labels right-to-left (0s at right).
  /// Historical mode: Oldest data on left, newest on right, labels left-to-right (0s at left).
  final bool isLiveMode;

  /// Creates a heart rate chart widget.
  const HeartRateChart({
    required this.readings,
    required this.windowSeconds,
    required this.lineColor,
    this.zoneColorResolver,
    this.zoneColorOpacity = 1.0,
    this.referenceTime,
    this.isLiveMode = true,
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

    // Filter readings and calculate window based on mode
    final List<HeartRateReading> visibleReadings;
    final DateTime windowStart;

    if (isLiveMode) {
      // Live mode: Show recent data within time window from now
      final now = referenceTime ?? DateTime.now();
      windowStart = now.subtract(Duration(seconds: windowSeconds));
      visibleReadings = readings
          .where((r) => r.timestamp.isAfter(windowStart))
          .toList();
    } else {
      // Historical mode: Show all readings, use first reading as start
      visibleReadings = readings;
      windowStart = readings.isNotEmpty
          ? readings.first.timestamp
          : DateTime.now();
    }

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
    final spots = _createSpots(visibleReadings, windowStart, isLiveMode);

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
                  if (value >= yMax - 0.5) {
                    return const SizedBox.shrink();
                  }
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
                  String formatMinutes(int seconds) {
                    final minutes = seconds / 60.0;
                    return minutes % 1 == 0
                        ? '${minutes.toStringAsFixed(0)}m'
                        : '${minutes.toStringAsFixed(1)}m';
                  }

                  if (isLiveMode) {
                    // Live mode: Right = 0s (now), Left = windowSeconds (oldest)
                    final seconds = windowSeconds - value.toInt();
                    return Text(
                      formatMinutes(seconds),
                      style: theme.textTheme.bodySmall,
                    );
                  } else {
                    // Historical mode: Left = 0s (start), Right = duration (end)
                    final seconds = value.toInt();
                    return Text(
                      formatMinutes(seconds),
                      style: theme.textTheme.bodySmall,
                    );
                  }
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
          lineBarsData: zoneColorResolver == null
              ? [
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
                ]
              : _createZoneLineBars(
                  visibleReadings,
                  windowStart,
                  zoneColorResolver!,
                  zoneColorOpacity,
                ),
        ),
      ),
    );
  }

  /// Converts heart rate readings to chart spots.
  ///
  /// In live mode: Newest data on right, oldest on left (standard positioning)
  /// In historical mode: Oldest on left, newest on right (standard positioning)
  /// Y-axis values are BPM values.
  List<FlSpot> _createSpots(
    List<HeartRateReading> readings,
    DateTime windowStart,
    bool isLiveMode,
  ) {
    return readings.map((reading) {
      // Calculate X position (seconds from window start)
      final xSeconds = reading.timestamp.difference(windowStart).inSeconds;

      // Both modes use the same positioning: older readings have lower X values
      // Live mode: oldest = 0, newest = windowSeconds (with countdown labels)
      // Historical mode: oldest = 0, newest = duration (with count-up labels)
      return FlSpot(xSeconds.toDouble(), reading.bpm.toDouble());
    }).toList();
  }

  List<LineChartBarData> _createZoneLineBars(
    List<HeartRateReading> readings,
    DateTime windowStart,
    Color Function(HeartRateReading reading) zoneColorResolver,
    double zoneColorOpacity,
  ) {
    if (readings.isEmpty) {
      return const [];
    }

    final opacity = zoneColorOpacity.clamp(0.0, 1.0);
    final coloredSpots = readings.map((reading) {
      final xSeconds = reading.timestamp.difference(windowStart).inSeconds;
      final baseColor = zoneColorResolver(reading);
      return _ColoredSpot(
        FlSpot(xSeconds.toDouble(), reading.bpm.toDouble()),
        baseColor.withValues(alpha: opacity),
      );
    }).toList();

    final List<LineChartBarData> bars = [];
    var currentColor = coloredSpots.first.color;
    var currentColorValue = coloredSpots.first.color.toARGB32();
    var currentSpots = <FlSpot>[coloredSpots.first.spot];

    for (var i = 1; i < coloredSpots.length; i++) {
      final entry = coloredSpots[i];
      final entryColorValue = entry.color.toARGB32();
      if (entryColorValue != currentColorValue) {
        bars.add(_buildBarData(currentSpots, currentColor, opacity));
        currentSpots = [currentSpots.last, entry.spot];
        currentColor = entry.color;
        currentColorValue = entryColorValue;
      } else {
        currentSpots.add(entry.spot);
      }
    }

    bars.add(_buildBarData(currentSpots, currentColor, opacity));
    return bars;
  }

  LineChartBarData _buildBarData(
    List<FlSpot> spots,
    Color color,
    double opacity,
  ) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1 * opacity),
      ),
    );
  }
}

class _ColoredSpot {
  final FlSpot spot;
  final Color color;

  const _ColoredSpot(this.spot, this.color);
}
