import 'package:flutter/material.dart';

class DesktopEncryptionWarningDialog extends StatefulWidget {
  const DesktopEncryptionWarningDialog({super.key});

  @override
  State<DesktopEncryptionWarningDialog> createState() =>
      _DesktopEncryptionWarningDialogState();
}

class _DesktopEncryptionWarningDialogState
    extends State<DesktopEncryptionWarningDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Desktop Encryption Warning'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'On desktop platforms, the database is stored unencrypted. '
            'For maximum privacy, use the mobile app on Android or iOS.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _dontShowAgain,
                onChanged: (value) {
                  setState(() => _dontShowAgain = value ?? false);
                },
              ),
              const SizedBox(width: 8),
              const Expanded(child: Text("Don't show again")),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_dontShowAgain),
          child: const Text('I Understand'),
        ),
      ],
    );
  }
}
