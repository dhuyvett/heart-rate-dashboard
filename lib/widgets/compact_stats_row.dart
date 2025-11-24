import 'package:flutter/material.dart';

/// A compact, single-row widget that displays session statistics.
///
/// Used when vertical space is constrained. Shows Duration, Average,
/// Minimum, and Maximum values in a horizontal arrangement.
///
/// Example usage:
/// ```dart
/// CompactStatsRow(
///   duration: '00:15:30',
///   avgHr: '142',
///   minHr: '98',
///   maxHr: '175',
/// )
/// ```
class CompactStatsRow extends StatelessWidget {
  /// The formatted duration string (e.g., "00:15:30").
  final String duration;

  /// The average heart rate value (e.g., "142" or "--").
  final String avgHr;

  /// The minimum heart rate value (e.g., "98" or "--").
  final String minHr;

  /// The maximum heart rate value (e.g., "175" or "--").
  final String maxHr;

  /// Creates a compact statistics row.
  const CompactStatsRow({
    required this.duration,
    required this.avgHr,
    required this.minHr,
    required this.maxHr,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              icon: Icons.timer,
              label: duration,
              color: theme.colorScheme.primary,
            ),
            _buildDivider(theme),
            _buildStatItem(
              context,
              icon: Icons.favorite,
              label: avgHr,
              sublabel: 'Avg',
              color: theme.colorScheme.primary,
            ),
            _buildDivider(theme),
            _buildStatItem(
              context,
              icon: Icons.arrow_downward,
              label: minHr,
              sublabel: 'Min',
              color: Colors.blue,
            ),
            _buildDivider(theme),
            _buildStatItem(
              context,
              icon: Icons.arrow_upward,
              label: maxHr,
              sublabel: 'Max',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? sublabel,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (sublabel != null) ...[
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      height: 24,
      width: 1,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
    );
  }
}
