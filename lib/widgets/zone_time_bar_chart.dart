import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/heart_rate_zone.dart';
import '../utils/heart_rate_zone_calculator.dart';

/// Bar chart showing time spent in each heart rate zone.
class ZoneTimeBarChart extends StatelessWidget {
  final Map<HeartRateZone, Duration> zoneDurations;
  final Map<HeartRateZone, (int, int)> zoneRanges;

  const ZoneTimeBarChart({
    required this.zoneDurations,
    required this.zoneRanges,
    super.key,
  });

  static const List<HeartRateZone> _orderedZones = [
    HeartRateZone.resting,
    HeartRateZone.zone1,
    HeartRateZone.zone2,
    HeartRateZone.zone3,
    HeartRateZone.zone4,
    HeartRateZone.zone5,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxMinutes = _orderedZones
        .map((zone) => _toMinutes(zoneDurations[zone]))
        .fold<double>(
          0,
          (maxValue, value) => value > maxValue ? value : maxValue,
        );

    if (maxMinutes <= 0) {
      return Center(
        child: Text(
          'No zone data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    final maxY = (maxMinutes * 1.2).clamp(1.0, double.infinity);
    final interval = _yAxisInterval(maxY);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                enabled: true,
                handleBuiltInTouches: false,
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding: EdgeInsets.zero,
                  tooltipMargin: 4,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) => Colors.transparent,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (rod.toY <= 0) {
                      return null;
                    }
                    final zone = _orderedZones[groupIndex];
                    final duration = zoneDurations[zone] ?? Duration.zero;
                    final textStyle = theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    );
                    return BarTooltipItem(
                      _formatDuration(duration),
                      textStyle ?? const TextStyle(fontSize: 12),
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: interval,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
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
                    reservedSize: 32,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value >= maxY - 0.001) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.toStringAsFixed(0),
                        style: theme.textTheme.bodySmall,
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= _orderedZones.length) {
                        return const SizedBox.shrink();
                      }
                      final zone = _orderedZones[index];
                      return Text(
                        '${_zoneLabel(zone)}\n'
                        '${_zoneBpmRangeLabel(zone, zoneRanges)}',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      );
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
              barGroups: _orderedZones.asMap().entries.map((entry) {
                final index = entry.key;
                final zone = entry.value;
                final minutes = _toMinutes(zoneDurations[zone]);
                return BarChartGroupData(
                  x: index,
                  showingTooltipIndicators: minutes > 0 ? [0] : const [],
                  barRods: [
                    BarChartRodData(
                      toY: minutes,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                      color: HeartRateZoneCalculator.getColorForZone(zone),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Minutes',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  static double _toMinutes(Duration? duration) {
    if (duration == null) return 0;
    return duration.inSeconds / 60.0;
  }

  static double _yAxisInterval(double maxY) {
    if (maxY <= 5) return 1;
    if (maxY <= 15) return 2;
    if (maxY <= 30) return 5;
    return 10;
  }

  static String _zoneLabel(HeartRateZone zone) {
    switch (zone) {
      case HeartRateZone.resting:
        return 'Rest';
      case HeartRateZone.zone1:
        return 'Very Light';
      case HeartRateZone.zone2:
        return 'Light';
      case HeartRateZone.zone3:
        return 'Moderate';
      case HeartRateZone.zone4:
        return 'Hard';
      case HeartRateZone.zone5:
        return 'Max';
    }
  }

  static String _zoneBpmRangeLabel(
    HeartRateZone zone,
    Map<HeartRateZone, (int, int)> zoneRanges,
  ) {
    final range = zoneRanges[zone];
    if (range == null) {
      return '-- bpm';
    }
    final (minBpm, maxBpm) = range;
    return '$minBpm-$maxBpm';
  }

  static String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final value = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:'
              '${minutes.toString().padLeft(2, '0')}:'
              '${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:'
              '${seconds.toString().padLeft(2, '0')}';
    return value.startsWith('0') ? value.substring(1) : value;
  }
}
