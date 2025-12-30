import 'package:flutter/material.dart';

/// Battery icon that fills based on the current percentage.
class BatteryLevelIcon extends StatelessWidget {
  final int? level;
  final double size;

  const BatteryLevelIcon({required this.level, this.size = 22, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = level != null
        ? (level! < 0 ? 0 : (level! > 100 ? 100 : level!))
        : null;
    final fillFraction = clamped != null ? clamped / 100 : null;
    final fillColor = clamped == null
        ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
        : clamped <= 20
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    final percentageTextColor = clamped != null && clamped >= 50
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return CustomPaint(
      size: Size(size * 1.8, size),
      painter: _BatteryPainter(
        fillFraction: fillFraction,
        fillColor: fillColor,
        outlineColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        percentage: clamped,
        percentageTextStyle: theme.textTheme.labelSmall?.copyWith(
          color: percentageTextColor,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.45,
        ),
      ),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final double? fillFraction;
  final Color fillColor;
  final Color outlineColor;
  final int? percentage;
  final TextStyle? percentageTextStyle;

  _BatteryPainter({
    required this.fillFraction,
    required this.fillColor,
    required this.outlineColor,
    required this.percentage,
    required this.percentageTextStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.height * 0.08;
    final terminalWidth = size.width * 0.12;
    final bodyWidth = size.width - terminalWidth;
    final radius = Radius.circular(size.height * 0.2);

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, bodyWidth, size.height),
      radius,
    );
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = outlineColor
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(bodyRect, outlinePaint);

    final innerWidth = bodyWidth - (strokeWidth * 2);
    final innerHeight = size.height - (strokeWidth * 2);
    if (fillFraction != null && innerWidth > 0 && innerHeight > 0) {
      final fillRatio = fillFraction!.clamp(0.0, 1.0).toDouble();
      final filledWidth = innerWidth * fillRatio;
      if (filledWidth > 0) {
        final fillRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(strokeWidth, strokeWidth, filledWidth, innerHeight),
          radius,
        );
        final fillPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = fillColor;
        canvas.drawRRect(fillRect, fillPaint);
      }
    }

    final terminalRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        bodyWidth,
        size.height * 0.3,
        terminalWidth * 0.7,
        size.height * 0.4,
      ),
      Radius.circular(size.height * 0.08),
    );
    canvas.drawRRect(terminalRect, outlinePaint);

    if (percentage != null && percentageTextStyle != null) {
      final textPainter = TextPainter(
        text: TextSpan(text: '${percentage!}%', style: percentageTextStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: bodyWidth);
      final textOffset = Offset(
        (bodyWidth - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) {
    return oldDelegate.fillFraction != fillFraction ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.percentage != percentage ||
        oldDelegate.percentageTextStyle != percentageTextStyle;
  }
}
