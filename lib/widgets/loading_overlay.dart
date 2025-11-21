import 'package:flutter/material.dart';

/// A full-screen semi-transparent loading overlay.
///
/// Use this widget to indicate that an async operation is in progress
/// and prevent user interaction. Can display an optional message.
///
/// Example usage:
/// ```dart
/// Stack(
///   children: [
///     // Your main content
///     MyMainWidget(),
///     // Conditionally show overlay
///     if (isLoading)
///       LoadingOverlay(message: 'Connecting...'),
///   ],
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  /// Optional message to display below the spinner.
  final String? message;

  /// Secondary message to display below the main message.
  final String? submessage;

  /// Background color of the overlay.
  /// Defaults to semi-transparent black.
  final Color? backgroundColor;

  /// Whether to show a card behind the spinner.
  final bool showCard;

  /// Creates a loading overlay.
  const LoadingOverlay({
    this.message,
    this.submessage,
    this.backgroundColor,
    this.showCard = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
        if (submessage != null) ...[
          const SizedBox(height: 8),
          Text(
            submessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    return Container(
      color: backgroundColor ?? Colors.black54,
      child: Center(
        child: showCard
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: content,
                ),
              )
            : content,
      ),
    );
  }
}

/// A loading overlay specifically for reconnection attempts.
///
/// Displays the current attempt number and optionally the last known BPM.
class ReconnectionOverlay extends StatelessWidget {
  /// The current reconnection attempt number.
  final int currentAttempt;

  /// The maximum number of attempts.
  final int maxAttempts;

  /// The last known BPM value (optional).
  final int? lastKnownBpm;

  /// Creates a reconnection overlay.
  const ReconnectionOverlay({
    required this.currentAttempt,
    this.maxAttempts = 10,
    this.lastKnownBpm,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Reconnecting...', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Attempt $currentAttempt of $maxAttempts',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (lastKnownBpm != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Last: $lastKnownBpm BPM',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple inline loading indicator with optional message.
///
/// Use this for inline loading states rather than full-screen overlays.
class InlineLoadingIndicator extends StatelessWidget {
  /// Optional message to display next to the spinner.
  final String? message;

  /// Creates an inline loading indicator.
  const InlineLoadingIndicator({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message == null) {
      return const CircularProgressIndicator();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(message!, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
