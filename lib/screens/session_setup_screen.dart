import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'heart_rate_monitoring_screen.dart';

/// Screen for naming a session before starting recording.
///
/// Opens with a pre-filled default name and requires a non-empty value
/// before enabling the Start action.
class SessionSetupScreen extends StatefulWidget {
  final String deviceName;

  const SessionSetupScreen({required this.deviceName, super.key});

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _buildDefaultName());
    _nameFocusNode = FocusNode();
    _nameFocusNode.addListener(() {
      if (_nameFocusNode.hasFocus) {
        _nameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _nameController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _buildDefaultName() {
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return 'Session - ${formatter.format(DateTime.now())}';
  }

  Future<void> _startSession() async {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) return;

    setState(() {
      _starting = true;
    });

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HeartRateMonitoringScreen(
          deviceName: widget.deviceName,
          sessionName: trimmedName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNameEmpty = _nameController.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Name Session')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set the session name', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              onChanged: (_) => setState(() {}),
              onTap: () {
                _nameController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _nameController.text.length,
                );
              },
              decoration: const InputDecoration(labelText: 'Session name'),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _starting
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    child: const Text('Back to devices'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _starting || isNameEmpty ? null : _startSession,
                    icon: const Icon(Icons.play_arrow),
                    label: _starting
                        ? const Text('Starting...')
                        : const Text('Start'),
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
