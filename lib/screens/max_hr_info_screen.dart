import 'package:flutter/material.dart';

/// Information screen explaining max heart rate calculation methods.
class MaxHRInfoScreen extends StatelessWidget {
  const MaxHRInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Max Heart Rate Calculations')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Introduction
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Max Heart Rate',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Maximum heart rate (MHR) is the highest number of beats per minute your heart can achieve during maximum physical exertion. It is used to calculate your heart rate training zones.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Different formulas estimate MHR based on age and sometimes sex. Choose the method that best suits your needs, or enter a custom value if you know your actual maximum heart rate.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Fox Formula
          _buildMethodCard(
            theme: theme,
            title: 'Fox Formula',
            formula: '220 - age',
            description:
                'The classic and most widely known formula. Simple and easy to remember, but may overestimate MHR for younger individuals and underestimate it for older individuals.',
            applicability: 'Applies to both men and women',
            icon: Icons.timeline,
            color: Colors.blue,
          ),

          const SizedBox(height: 12),

          // HUNT Formula
          _buildMethodCard(
            theme: theme,
            title: 'HUNT Formula',
            formula: '211 - (0.64 × age)',
            description:
                'Based on a large Norwegian fitness study (HUNT). Provides a more gradual decline in MHR with age compared to the Fox formula.',
            applicability: 'Applies to both men and women',
            icon: Icons.show_chart,
            color: Colors.green,
          ),

          const SizedBox(height: 12),

          // Tanaka Formula
          _buildMethodCard(
            theme: theme,
            title: 'Tanaka Formula',
            formula: '208 - (0.7 × age)',
            description:
                'Developed from a meta-analysis of published studies. Considered more accurate for older adults and trained athletes than the Fox formula.',
            applicability: 'Applies to both men and women',
            icon: Icons.fitness_center,
            color: Colors.orange,
          ),

          const SizedBox(height: 12),

          // Shargal Formula
          _buildMethodCard(
            theme: theme,
            title: 'Shargal Formula',
            formula:
                'Men: 208.609 - (0.71 × age)\nWomen: 209.273 - (0.804 × age)',
            description:
                'The only formula that differentiates based on biological sex. Uses sex-specific values because physiological differences affect maximum heart rate calculations. May provide more accurate estimates when sex is taken into account.',
            applicability: 'Sex-specific calculation',
            icon: Icons.people,
            color: Colors.purple,
          ),

          const SizedBox(height: 12),

          // Custom
          _buildMethodCard(
            theme: theme,
            title: 'Custom',
            formula: 'User-defined value',
            description:
                'If you have determined your actual maximum heart rate through a lab test or supervised exercise test, you can enter it directly here for the most accurate zone calculations.',
            applicability: 'For known MHR values (100-220 BPM)',
            icon: Icons.edit,
            color: Colors.teal,
          ),

          const SizedBox(height: 16),

          // Note
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Note: These formulas provide estimates. For the most accurate maximum heart rate, consult with a healthcare professional or undergo a supervised exercise test.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required ThemeData theme,
    required String title,
    required String formula,
    required String description,
    required String applicability,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calculate,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formula,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    applicability,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
