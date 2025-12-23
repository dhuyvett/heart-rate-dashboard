import 'package:flutter/material.dart';

/// First-launch disclaimer explaining the non-medical nature of the app.
class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key, required this.onAcknowledged});

  final VoidCallback onAcknowledged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Safety Disclaimer')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Icon(
                          Icons.favorite,
                          size: 72,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Informational Only',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Heart rate levels and ranges in this app are based on '
                        'publicly available formulas and are estimates only. This '
                        'application is not a medical device and the information '
                        'displayed should not be treated as medical advice, '
                        'diagnosis, or treatment.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Consult your doctor before starting or changing any '
                        'exercise program. Stop using the app and seek medical '
                        'attention if you feel unwell.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAcknowledged,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('I Understand'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
