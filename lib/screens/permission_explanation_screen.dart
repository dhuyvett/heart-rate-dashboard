import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'device_selection_screen.dart';

/// Screen that explains why Bluetooth permissions are needed.
///
/// Displays before the first permission request to help users understand
/// why the app needs Bluetooth access. Handles platform-specific permission
/// requirements (Android 11 and below requires location for BLE scanning).
///
/// Auto-navigates to device selection if permissions are already granted.
class PermissionExplanationScreen extends StatefulWidget {
  const PermissionExplanationScreen({super.key});

  @override
  State<PermissionExplanationScreen> createState() =>
      _PermissionExplanationScreenState();
}

class _PermissionExplanationScreenState
    extends State<PermissionExplanationScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Check if permissions are already granted
    _checkPermissions();
  }

  /// Checks if required permissions are already granted.
  ///
  /// If granted, automatically navigates to device selection.
  Future<void> _checkPermissions() async {
    final hasPermissions = await _hasRequiredPermissions();
    if (hasPermissions && mounted) {
      _navigateToDeviceSelection();
    }
  }

  Future<bool> _requiresAndroidLocationPermission() async {
    if (!Platform.isAndroid) return false;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.sdkInt < 31;
  }

  /// Checks if all required permissions are granted.
  Future<bool> _hasRequiredPermissions() async {
    if (Platform.isAndroid) {
      // Android requires Bluetooth permissions; location is only required
      // for BLE scanning on Android 11 and below.
      final bluetoothScan = await Permission.bluetoothScan.isGranted;
      final bluetoothConnect = await Permission.bluetoothConnect.isGranted;
      final requiresLocation = await _requiresAndroidLocationPermission();
      final location = await Permission.locationWhenInUse.isGranted;

      return bluetoothScan &&
          bluetoothConnect &&
          (!requiresLocation || location);
    } else if (Platform.isIOS) {
      // iOS only requires Bluetooth permission
      return await Permission.bluetooth.isGranted;
    } else {
      // For other platforms (desktop), assume permissions are granted
      return true;
    }
  }

  /// Requests the required Bluetooth permissions.
  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<Permission, PermissionStatus> statuses;

      bool allGranted;

      if (Platform.isAndroid) {
        final requiresLocation = await _requiresAndroidLocationPermission();
        // Request Android permissions
        statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ].request();
        final bluetoothScanGranted =
            statuses[Permission.bluetoothScan]?.isGranted ?? false;
        final bluetoothConnectGranted =
            statuses[Permission.bluetoothConnect]?.isGranted ?? false;
        final locationGranted =
            statuses[Permission.locationWhenInUse]?.isGranted ?? false;
        allGranted =
            bluetoothScanGranted &&
            bluetoothConnectGranted &&
            (!requiresLocation || locationGranted);
      } else if (Platform.isIOS) {
        // Request iOS permission
        statuses = await [Permission.bluetooth].request();
        allGranted = statuses.values.every((status) => status.isGranted);
      } else {
        // Desktop platforms - no permission request needed
        _navigateToDeviceSelection();
        return;
      }

      if (allGranted) {
        _navigateToDeviceSelection();
      } else {
        setState(() {
          _errorMessage =
              'Bluetooth permission is required to connect to '
              'heart rate monitors. Please grant the necessary permissions.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'An error occurred while requesting permissions. '
            'Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Navigates to the device selection screen.
  void _navigateToDeviceSelection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DeviceSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Permission')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bluetooth_searching,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Bluetooth Access Required',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This app needs Bluetooth access to connect to your '
                'heart rate monitor.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (Platform.isAndroid) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Location permission is required by Android for '
                          'Bluetooth scanning on Android 11 and below and '
                          'enables speed/distance stats. Your location is '
                          'not tracked.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _requestPermissions,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _errorMessage != null ? 'Retry' : 'Grant Permission',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
