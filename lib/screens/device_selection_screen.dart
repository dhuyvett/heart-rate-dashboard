import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scanned_device.dart';
import '../providers/device_scan_provider.dart';
import '../providers/heart_rate_provider.dart';
import '../services/bluetooth_service.dart' as app_bt;
import '../utils/app_logger.dart';
import '../utils/error_messages.dart';
import '../widgets/device_list_tile.dart';
import '../widgets/loading_overlay.dart';
import 'about_screen.dart';
import 'heart_rate_monitoring_screen.dart';
import 'session_history_screen.dart';
import 'settings_screen.dart';

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
  static final _logger = AppLogger.getLogger('DeviceSelectionScreen');
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectingDeviceName;
  String? _errorMessage;
  bool _bluetoothEnabled = true;
  bool _checkingBluetooth = true;
  StreamSubscription<BluetoothAdapterState>? _bluetoothStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBluetoothState();
  }

  /// Initializes Bluetooth state checking with error handling.
  Future<void> _initializeBluetoothState() async {
    try {
      await _checkBluetoothState();
      await _listenToBluetoothState();
    } catch (e) {
      // Platform not supported or error - assume Bluetooth is available
      if (mounted) {
        setState(() {
          _bluetoothEnabled = true;
          _checkingBluetooth = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bluetoothStateSubscription?.cancel();
    super.dispose();
  }

  /// Checks the current Bluetooth adapter state.
  Future<void> _checkBluetoothState() async {
    setState(() {
      _checkingBluetooth = true;
    });

    try {
      final state = await FlutterBluePlus.adapterState.first;
      if (mounted) {
        setState(() {
          _bluetoothEnabled = state == BluetoothAdapterState.on;
          _checkingBluetooth = false;
        });
      }
    } catch (e) {
      // Platform not supported or other error - assume Bluetooth is available
      if (mounted) {
        setState(() {
          _bluetoothEnabled = true;
          _checkingBluetooth = false;
        });
      }
    }
  }

  /// Listens to Bluetooth adapter state changes.
  Future<void> _listenToBluetoothState() async {
    try {
      final stream = FlutterBluePlus.adapterState;
      _bluetoothStateSubscription = stream.listen(
        (state) {
          if (mounted) {
            setState(() {
              _bluetoothEnabled = state == BluetoothAdapterState.on;
            });
          }
        },
        onError: (e) {
          // Platform not supported or error - assume Bluetooth available
          if (mounted) {
            setState(() {
              _bluetoothEnabled = true;
              _checkingBluetooth = false;
            });
          }
        },
      );
    } catch (e) {
      // Platform not supported - Bluetooth state tracking unavailable
    }
  }

  /// Requests to turn on Bluetooth.
  Future<void> _requestEnableBluetooth() async {
    try {
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      } else if (Platform.isLinux) {
        // Try to open Linux Bluetooth settings
        await _openLinuxBluetoothSettings();
      } else if (Platform.isMacOS) {
        // Open macOS Bluetooth preferences
        await Process.run('open', [
          'x-apple.systempreferences:com.apple.preferences.Bluetooth',
        ]);
      } else if (Platform.isWindows) {
        // Open Windows Bluetooth settings
        await Process.run('explorer', ['ms-settings:bluetooth']);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Could not open Bluetooth settings. Please enable Bluetooth manually.';
        });
      }
    }
  }

  /// Attempts to open Linux Bluetooth settings.
  Future<void> _openLinuxBluetoothSettings() async {
    // Try common Linux desktop environment settings apps
    final commands = [
      [
        'gnome-control-center',
        ['bluetooth'],
      ], // GNOME
      ['blueman-manager', <String>[]], // Blueman (common on many distros)
      [
        'systemsettings5',
        ['kcm_bluetooth'],
      ], // KDE Plasma 5
      ['blueberry', <String>[]], // Linux Mint/Cinnamon
    ];

    for (final cmd in commands) {
      try {
        final result = await Process.run('which', [cmd[0] as String]);
        if (result.exitCode == 0) {
          await Process.start(
            cmd[0] as String,
            cmd[1] as List<String>,
            mode: ProcessStartMode.detached,
          );
          return;
        }
      } catch (e) {
        continue;
      }
    }

    // If no settings app found, show error
    if (mounted) {
      setState(() {
        _errorMessage =
            'Could not find Bluetooth settings. Please enable Bluetooth using your system settings.';
      });
    }
  }

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
      final bluetoothService = app_bt.BluetoothService.instance;

      // Invalidate the heart rate provider to ensure a fresh start.
      // This is necessary when reconnecting after a previous session,
      // as the old provider's stream may have completed.
      ref.invalidate(heartRateProvider);

      // Debug logging
      _logger.d(
        'Attempting to connect to device: ${device.id} (${device.name})',
      );

      // Connect to device (works for both demo and real devices)
      await bluetoothService.connectToDevice(device.id);

      // Debug logging
      _logger.i('Successfully connected to device: ${device.name}');

      // Navigate to monitoring screen on successful connection
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                HeartRateMonitoringScreen(deviceName: device.name),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Debug logging
      _logger.e('Error connecting to device', error: e, stackTrace: stackTrace);

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
      appBar: AppBar(
        title: const Text('Select Heart Rate Monitor'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onSelected: (value) {
              if (value == 'session_history') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SessionHistoryScreen(),
                  ),
                );
              } else if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              } else if (value == 'about') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'session_history',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 12),
                    Text('Session History'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 12),
                    Text('About'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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

              // Bluetooth disabled banner
              if (!_checkingBluetooth && !_bluetoothEnabled)
                _BluetoothDisabledBanner(onEnable: _requestEnableBluetooth),

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
    final isBluetoothOffError =
        errorMessage.toLowerCase().contains('powered off') ||
        errorMessage.toLowerCase().contains('off');

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
            if (isBluetoothOffError) ...[
              const SizedBox(height: 12),
              Text(
                'Try enabling Bluetooth in your system settings.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
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

/// Banner shown when Bluetooth is disabled.
class _BluetoothDisabledBanner extends StatelessWidget {
  final VoidCallback onEnable;

  const _BluetoothDisabledBanner({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAndroid = Platform.isAndroid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.secondaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bluetooth_disabled,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bluetooth is turned off',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Turn on Bluetooth to scan for heart rate monitors.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onEnable,
              icon: const Icon(Icons.bluetooth),
              label: Text(isAndroid ? 'Enable Bluetooth' : 'Open Settings'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
