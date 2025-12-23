import 'package:flutter/material.dart';

/// A compact, single-row widget that displays session statistics.
///
/// Used when vertical space is constrained. Accepts a list of stats to show
/// and keeps them on a single row using a fitted layout.
class CompactStatsRow extends StatelessWidget {
  /// Statistics to display.
  final List<CompactStat> stats;

  /// Creates a compact statistics row.
  const CompactStatsRow({required this.stats, super.key});

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
          children: _buildChildren(theme),
        ),
      ),
    );
  }

  List<Widget> _buildChildren(ThemeData theme) {
    final widgets = <Widget>[];

    for (var i = 0; i < stats.length; i++) {
      final stat = stats[i];
      widgets.add(
        _buildStatItem(
          theme,
          icon: stat.icon,
          label: stat.value,
          sublabel: stat.sublabel,
          color: stat.color,
        ),
      );

      if (i < stats.length - 1) {
        widgets.add(_buildDivider(theme));
      }
    }

    return widgets;
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    String? sublabel,
    required Color color,
  }) {
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

/// Model for a compact statistic entry.
class CompactStat {
  final IconData icon;
  final String value;
  final String? sublabel;
  final Color color;

  const CompactStat({
    required this.icon,
    required this.value,
    this.sublabel,
    required this.color,
  });
}
