import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/gps_sample.dart';

/// Line chart for GPS-derived metrics (speed, altitude) over time.
class GpsMetricChart extends StatelessWidget {
  /// GPS samples sorted by timestamp (oldest to newest).
  final List<GpsSample> samples;

  /// Session start time used to anchor the X-axis.
  final DateTime sessionStart;

  /// Total session duration in seconds.
  final int windowSeconds;

  /// Extracts the metric value from a sample; return null to skip.
  final double? Function(GpsSample sample) valueSelector;

  /// Formats Y-axis values.
  final String Function(double value) valueFormatter;

  /// The color for the line and fill.
  final Color lineColor;

  /// Message to display when no data is available.
  final String emptyMessage;

  /// Optional floor for the y-axis minimum.
  final double? minYFloor;

  /// Whether to render a smoothed curve instead of straight lines.
  final bool isCurved;

  const GpsMetricChart({
    required this.samples,
    required this.sessionStart,
    required this.windowSeconds,
    required this.valueSelector,
    required this.valueFormatter,
    required this.lineColor,
    required this.emptyMessage,
    this.minYFloor,
    this.isCurved = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (samples.isEmpty || windowSeconds <= 0) {
      return _buildEmptyState(theme);
    }

    final points = <FlSpot>[];
    final values = <double>[];

    for (final sample in samples) {
      final value = valueSelector(sample);
      if (value == null) continue;
      final deltaSeconds =
          sample.timestamp.difference(sessionStart).inMilliseconds / 1000;
      final x = deltaSeconds.clamp(0, windowSeconds).toDouble();
      points.add(FlSpot(x, value));
      values.add(value);
    }

    if (points.isEmpty) {
      return _buildEmptyState(theme);
    }

    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);
    if (minValue == maxValue) {
      minValue -= 1;
      maxValue += 1;
    }

    final padding = (maxValue - minValue) * 0.1;
    var yMin = minValue - padding;
    final yMax = maxValue + padding;
    if (minYFloor != null) {
      yMin = math.max(minYFloor!, yMin);
    }
    final yInterval = math.max((yMax - yMin) / 4, 1).toDouble();

    return _buildChart(theme, points, yMin, yMax, yInterval);
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Text(
        emptyMessage,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildChart(
    ThemeData theme,
    List<FlSpot> points,
    double yMin,
    double yMax,
    double yInterval,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: LineChart(
        LineChartData(
          clipData: const FlClipData.all(),
          minY: yMin,
          maxY: yMax,
          minX: 0,
          maxX: windowSeconds.toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: yInterval,
            verticalInterval: windowSeconds / 4.0,
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
                reservedSize: 44,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  if (value >= yMax - 0.5) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    valueFormatter(value),
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
                  final minutes = value / 60.0;
                  final label = minutes % 1 == 0
                      ? '${minutes.toStringAsFixed(0)}m'
                      : '${minutes.toStringAsFixed(1)}m';
                  return Text(label, style: theme.textTheme.bodySmall);
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
              spots: points,
              isCurved: isCurved,
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
}
