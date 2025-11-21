import 'package:flutter/material.dart';

/// A button action for the error dialog.
class ErrorDialogAction {
  /// The text to display on the button.
  final String label;

  /// Callback when the button is pressed.
  final VoidCallback onPressed;

  /// Whether this is the primary action.
  final bool isPrimary;

  /// Creates an error dialog action.
  const ErrorDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });
}

/// A reusable error dialog widget.
///
/// Displays an error message with customizable title, message, and action buttons.
/// Use this dialog to show user-friendly error messages throughout the app.
///
/// Example usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => ErrorDialog(
///     title: 'Connection Failed',
///     message: 'Could not connect to the device.',
///     actions: [
///       ErrorDialogAction(
///         label: 'Retry',
///         onPressed: () => Navigator.pop(context),
///         isPrimary: true,
///       ),
///       ErrorDialogAction(
///         label: 'Cancel',
///         onPressed: () => Navigator.pop(context),
///       ),
///     ],
///   ),
/// );
/// ```
class ErrorDialog extends StatelessWidget {
  /// The title of the dialog.
  final String title;

  /// The error message to display.
  final String message;

  /// The action buttons to display.
  final List<ErrorDialogAction> actions;

  /// Optional icon to display above the title.
  final IconData? icon;

  /// Creates an error dialog.
  const ErrorDialog({
    required this.title,
    required this.message,
    required this.actions,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        icon ?? Icons.error_outline,
        size: 48,
        color: theme.colorScheme.error,
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: actions.map((action) {
        if (action.isPrimary) {
          return FilledButton(
            onPressed: action.onPressed,
            child: Text(action.label),
          );
        }
        return TextButton(
          onPressed: action.onPressed,
          child: Text(action.label),
        );
      }).toList(),
    );
  }
}

/// Shows an error dialog with the given parameters.
///
/// This is a convenience function for showing error dialogs.
/// Returns a Future that completes when the dialog is dismissed.
Future<void> showErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  required List<ErrorDialogAction> actions,
  IconData? icon,
  bool barrierDismissible = true,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => ErrorDialog(
      title: title,
      message: message,
      actions: actions,
      icon: icon,
    ),
  );
}

/// Shows a simple error dialog with a single "OK" button.
///
/// This is a convenience function for simple error messages.
Future<void> showSimpleErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonLabel = 'OK',
  IconData? icon,
}) {
  return showErrorDialog(
    context: context,
    title: title,
    message: message,
    icon: icon,
    actions: [
      ErrorDialogAction(
        label: buttonLabel,
        onPressed: () => Navigator.of(context).pop(),
        isPrimary: true,
      ),
    ],
  );
}

/// Shows a connection failed dialog with retry and device selection options.
///
/// Returns true if the user chose to retry, false if they chose to select a device.
Future<bool> showConnectionFailedDialog({
  required BuildContext context,
  String? deviceName,
  int? attemptCount,
}) async {
  bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ErrorDialog(
      title: 'Connection Failed',
      message: attemptCount != null
          ? 'Could not reconnect after $attemptCount attempts. '
                'The device may be out of range or turned off.'
          : 'Could not connect to ${deviceName ?? 'the device'}. '
                'Make sure it\'s turned on and nearby.',
      icon: Icons.bluetooth_disabled,
      actions: [
        ErrorDialogAction(
          label: 'Select Device',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ErrorDialogAction(
          label: 'Retry',
          onPressed: () => Navigator.of(context).pop(true),
          isPrimary: true,
        ),
      ],
    ),
  );

  return result ?? false;
}
