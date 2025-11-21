import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scanned_device.dart';
import '../providers/device_scan_provider.dart';
import '../services/bluetooth_service.dart';
import '../utils/error_messages.dart';
import '../widgets/device_list_tile.dart';
import '../widgets/loading_overlay.dart';
import 'heart_rate_monitoring_screen.dart';

/// Screen for selecting and connecting to a Bluetooth heart rate monitor.
///
/// Displays a list of available devices including a demo mode option.
/// Handles scanning for devices, connection attempts, and error states.
class DeviceSelectionScreen extends ConsumerStatefulWidget {
  const DeviceSelectionScreen({super.key});

  @override
  ConsumerState<DeviceSelectionScreen> createState() =>
      _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends ConsumerState<DeviceSelectionScreen> {
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectingDeviceName;
  String? _errorMessage;

  /// Starts scanning for Bluetooth devices.
  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      // Scanning happens via the device scan provider
      // The stream will emit devices as they are discovered
      await Future.delayed(const Duration(seconds: 5));
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = getUserFriendlyErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  /// Connects to a selected device.
  Future<void> _connectToDevice(ScannedDevice device) async {
    setState(() {
      _isConnecting = true;
      _connectingDeviceName = device.name;
      _errorMessage = null;
    });

    try {
      final bluetoothService = BluetoothService.instance;

      // Connect to device (works for both demo and real devices)
      await bluetoothService.connectToDevice(device.id);

      // Navigate to monitoring screen on successful connection
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                HeartRateMonitoringScreen(deviceName: device.name),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = getUserFriendlyErrorMessage(
            e,
            deviceName: device.name,
          );
          _isConnecting = false;
          _connectingDeviceName = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final devicesAsync = ref.watch(deviceScanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Heart Rate Monitor')),
      body: Stack(
        children: [
          Column(
            children: [
              // Error message banner
              if (_errorMessage != null)
                _ErrorBanner(
                  message: _errorMessage!,
                  onDismiss: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                ),

              // Scan button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isScanning || _isConnecting ? null : _startScan,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.bluetooth_searching),
                    label: Text(
                      _isScanning ? 'Scanning...' : 'Scan for Devices',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),

              // Device list
              Expanded(
                child: devicesAsync.when(
                  data: (devices) {
                    // Separate demo device from real devices
                    final realDevices = devices
                        .where((d) => !d.isDemo)
                        .toList();

                    return ListView(
                      children: [
                        // Always show demo mode device first
                        ...devices
                            .where((d) => d.isDemo)
                            .map(
                              (device) => DeviceListTile(
                                device: device,
                                onTap: () => _connectToDevice(device),
                              ),
                            ),

                        // Show real devices if any
                        if (realDevices.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'Available Devices',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                          ...realDevices.map(
                            (device) => DeviceListTile(
                              device: device,
                              onTap: () => _connectToDevice(device),
                            ),
                          ),
                        ],

                        // Show no devices message if only demo mode available
                        if (realDevices.isEmpty && !_isScanning) ...[
                          const SizedBox(height: 32),
                          _EmptyDevicesState(onScan: _startScan),
                        ],
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading devices...'),
                      ],
                    ),
                  ),
                  error: (error, stack) => _BluetoothErrorState(
                    errorMessage: getUserFriendlyErrorMessage(error),
                    onRetry: _startScan,
                  ),
                ),
              ),
            ],
          ),

          // Loading overlay during connection
          if (_isConnecting)
            LoadingOverlay(
              message: 'Connecting...',
              submessage: _connectingDeviceName != null
                  ? 'To $_connectingDeviceName'
                  : null,
            ),
        ],
      ),
    );
  }
}

/// Error banner displayed at the top of the screen.
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onDismiss,
            color: theme.colorScheme.onErrorContainer,
          ),
        ],
      ),
    );
  }
}

/// Empty state shown when no devices are found.
class _EmptyDevicesState extends StatelessWidget {
  final VoidCallback onScan;

  const _EmptyDevicesState({required this.onScan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(
            Icons.bluetooth_disabled,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            errorNoDevicesFound,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }
}

/// Error state for Bluetooth-related errors.
class _BluetoothErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _BluetoothErrorState({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
