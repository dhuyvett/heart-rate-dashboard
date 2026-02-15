import 'package:flutter/material.dart';

/// Shared disclaimer copy used across screens.
class DisclaimerContent extends StatelessWidget {
  const DisclaimerContent({
    super.key,
    this.textStyle,
    this.textAlign = TextAlign.center,
    this.spacing = 16.0,
  });

  final TextStyle? textStyle;
  final TextAlign textAlign;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final style = textStyle ?? Theme.of(context).textTheme.bodyLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Heart rate levels and ranges in this app are based on publicly '
          'available formulas and are estimates only. This application is not '
          'a medical device and the information displayed should not be treated '
          'as medical advice, diagnosis, or treatment.',
          style: style,
          textAlign: textAlign,
        ),
        SizedBox(height: spacing),
        Text(
          'Readings may be inaccurate due to device fit, motion, battery level, '
          'or environmental factors. Do not use this app for emergency needs. '
          'If you have concerning symptoms, call emergency services.',
          style: style,
          textAlign: textAlign,
        ),
        SizedBox(height: spacing),
        Text(
          'Consult your doctor before starting or changing any exercise program. '
          'Stop using the app and seek medical attention if you feel unwell.',
          style: style,
          textAlign: textAlign,
        ),
      ],
    );
  }
}
