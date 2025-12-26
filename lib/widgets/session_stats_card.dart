import 'dart:math' as math;
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

  /// Scales icon and text sizes based on available space.
  final double scale;

  /// Creates a session statistics card.
  const SessionStatsCard({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.scale = 1.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final bodyFontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;
    final titleFontSize = theme.textTheme.titleLarge?.fontSize ?? 22;
    final iconScale = math.min(scale, 1.1);
    final labelScale = math.min(scale, 1.05);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final valueFontSize = math.min(
              titleFontSize * scale,
              constraints.maxHeight * 0.7,
            );

            return SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: effectiveIconColor,
                        size: 28 * iconScale,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: bodyFontSize * labelScale,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: valueFontSize,
                      fontFamily: 'SourceSans3',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
