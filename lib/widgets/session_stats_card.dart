import 'package:flutter/material.dart';

/// A card widget that displays a single session statistic.
///
/// Used to display metrics like duration, average HR, min HR, and max HR
/// in a consistent, readable format with an icon and label.
class SessionStatsCard extends StatelessWidget {
  /// Icon representing the statistic.
  final IconData icon;

  /// Label describing the statistic (e.g., "Average", "Duration").
  final String label;

  /// The value to display (e.g., "142 BPM", "10:30").
  final String value;

  /// Optional color for the icon. Defaults to theme color.
  final Color? iconColor;

  /// Creates a session statistics card.
  const SessionStatsCard({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: effectiveIconColor, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
