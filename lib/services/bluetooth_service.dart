import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/constants.dart';
import '../utils/app_logger.dart';
import 'database_service.dart';
import 'demo_mode_service.dart';

/// Custom connection states for tracking device connectivity in the app.
///
/// This enum extends the basic BLE connection states with app-specific states
/// like reconnecting.
enum ConnectionState {
  /// Device is not connected.
  disconnected,

  /// Connection attempt in progress.
  connecting,

  /// Device is successfully connected.
  connected,

  /// Attempting to reconnect after unexpected disconnection.
  reconnecting,
}

/// Service for managing Bluetooth Low Energy device connections and heart rate data.
///
/// This service handles:
/// - Device scanning for HR monitors (BLE Heart Rate Service 0x180D)
/// - Device connection and disconnection
/// - Heart rate data subscription and parsing (characteristic 0x2A37)
/// - Connection state monitoring
/// - Demo mode for testing without physical hardware
///
/// Uses singleton pattern to ensure only one BLE instance exists.
class BluetoothService {
  // Logger instance
  static final _logger = AppLogger.getLogger('BluetoothService');

  // Singleton instance
  static BluetoothService _instance = BluetoothService._internal();

  /// Primary access point for the singleton instance.
  static BluetoothService get instance => _instance;

  /// Allows tests to swap in a fake or controlled instance.
  @visibleForTesting
  static set debugInstance(BluetoothService service) {
    _instance = service;
  }

  /// Creates a test-friendly instance with injectable behaviors.
  @visibleForTesting
  factory BluetoothService.test({
    Stream<ConnectionState>? connectionStateStream,
    Future<void> Function(String deviceId)? onConnect,
    Future<void> Function()? onRestartHeartRate,
  }) {
    return _TestBluetoothService(
      connectionStateStream: connectionStateStream,
      onConnect: onConnect,
      onRestartHeartRate: onRestartHeartRate,
    );
  }

  // Current connection state
  ConnectionState _connectionState = ConnectionState.disconnected;

  // Currently connected device
  BluetoothDevice? _connectedDevice;

  // Whether currently connected to demo mode
  bool _isInDemoMode = false;

  // Connected device name (for demo mode tracking)
  String? _connectedDeviceName;

  /// Timeout used for BLE connections. Overridable in tests.
  static Duration connectionTimeout = const Duration(seconds: 15);

  // Stream controllers for managing data flows
  final StreamController<List<BluetoothDevice>> _scanResultsController =
      StreamController<List<BluetoothDevice>>.broadcast();
  final StreamController<int> _heartRateController =
      StreamController<int>.broadcast();
  final StreamController<ConnectionState> _connectionStateController =
      StreamController<ConnectionState>.broadcast();
  final StreamController<int?> _batteryLevelController =
      StreamController<int?>.broadcast();

  // Subscriptions for cleanup
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _deviceStateSubscription;
  StreamSubscription<List<int>>? _heartRateSubscription;
  StreamSubscription<List<int>>? _batteryLevelSubscription;
  StreamSubscription<int>? _demoModeSubscription;
  Timer? _scanFallbackTimer;
  bool _allowAllDevices = false;
  int? _batteryLevel;

  // Cache of devices seen during the most recent scan.
  final Map<String, BluetoothDevice> _scannedDevices = {};

  // Private constructor for singleton
  BluetoothService._internal();

  /// Gets the current connection state.
  ConnectionState get connectionState => _connectionState;

  /// Gets the currently connected device, if any.
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Whether currently in demo mode.
  bool get isInDemoMode => _isInDemoMode;

  /// Gets the connected device name (works for both real devices and demo mode).
  String? get connectedDeviceName => _connectedDeviceName;

  /// Gets the most recent battery level (0-100), if available.
  int? get batteryLevel => _batteryLevel;

  /// Checks if the given device ID is for demo mode.
  static bool isDemoModeDevice(String deviceId) {
    return deviceId == demoModeDeviceId;
  }

  /// Starts scanning for BLE devices advertising Heart Rate Service (0x180D).
  ///
  /// Returns a stream of discovered devices.
  ///
  /// Throws [StateError] if Bluetooth adapter is not powered on.
  /// Throws [StateError] if location permission is not granted (Android).
  Stream<List<BluetoothDevice>> scanForDevices() async* {
    // Stop any existing scan first
    await stopScan();

    // List to accumulate unique devices
    final Map<String, BluetoothDevice> discoveredDevices = {};
    _scannedDevices.clear();
    _allowAllDevices = false;
    _scanFallbackTimer?.cancel();
    _scanFallbackTimer = Timer(const Duration(seconds: 5), () {
      if (discoveredDevices.isEmpty) {
        _allowAllDevices = true;
      }
    });

    // Start listening to scan results before starting the scan
    // This is important to catch all results on all platforms
    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        for (var result in results) {
          final deviceId = result.device.remoteId.str;

          if (discoveredDevices.containsKey(deviceId)) {
            continue;
          }

          final advertisement = result.advertisementData;
          final deviceName = advertisement.advName.isNotEmpty
              ? advertisement.advName
              : result.device.platformName;
          final hasHrService = advertisement.serviceUuids.any(
            (uuid) => _matchesUuid(uuid.str, bleHrServiceUuid),
          );
          final hasNoServiceData = advertisement.serviceUuids.isEmpty;
          final isLikelyHrDevice = _isLikelyHrDevice(deviceName);
          final hasName = deviceName.trim().isNotEmpty;
          if (!hasName && !hasHrService) {
            continue;
          }
          if (!hasHrService &&
              !hasNoServiceData &&
              !isLikelyHrDevice &&
              !_allowAllDevices) {
            continue;
          }

          discoveredDevices[deviceId] = result.device;
          _scannedDevices[deviceId] = result.device;
          _scanResultsController.add(discoveredDevices.values.toList());
        }
      },
      onError: (e, stackTrace) {
        // Log scan errors but don't crash
        _logger.e(
          'Scan results stream error',
          error: e,
          stackTrace: stackTrace,
        );
      },
    );

    // Start the scan in the background
    _startScanWithFallback();

    yield* _scanResultsController.stream;
  }

  /// Stops the current BLE scan.
  Future<void> stopScan() async {
    try {
      _scanFallbackTimer?.cancel();
      _scanFallbackTimer = null;
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      await FlutterBluePlus.stopScan();
    } catch (e, stackTrace) {
      // Log but don't crash - stopping scan might fail if it wasn't running
      _logger.w('Error in stopScan', error: e, stackTrace: stackTrace);
    }
  }

  /// Attempts to start scan without service filtering.
  ///
  /// This approach is more reliable on Linux.
  Future<void> _startScanWithFallback() async {
    try {
      // Start scanning without service filter - more reliable on Linux
      // and other platforms.
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
    } catch (e, stackTrace) {
      // Log error but don't crash - demo mode will still be available
      _logger.e('Bluetooth scan error', error: e, stackTrace: stackTrace);
    }
  }

  /// Connects to a BLE device or demo mode by its ID.
  ///
  /// [deviceId] is the unique identifier of the device to connect to.
  /// Use [demoModeDeviceId] to connect to demo mode.
  ///
  /// This method will:
  /// 1. For demo mode: Start demo mode service
  /// 2. For real devices:
  ///    - Initiate connection with 15-second timeout
  ///    - Discover services after connection
  ///    - Verify Heart Rate Service (0x180D) is present
  /// 3. Save device ID to settings for reconnection
  ///
  /// Throws [TimeoutException] if connection times out.
  /// Throws [StateError] if Heart Rate Service is not found.
  /// Throws [Exception] for other connection errors.
  Future<void> connectToDevice(String deviceId) async {
    if (this is _TestBluetoothService) {
      return (this as _TestBluetoothService)._handleTestConnect(deviceId);
    }

    // Check if this is demo mode
    if (isDemoModeDevice(deviceId)) {
      await _connectToDemoMode();
      return;
    }

    BluetoothDevice? connectedDeviceRef;
    try {
      // Update state to connecting
      _updateConnectionState(ConnectionState.connecting);
      _updateBatteryLevel(null);

      // Stop any existing scan
      await stopScan();

      // Find the device
      final device = await _findDeviceById(deviceId);
      if (device == null) {
        throw StateError('Device not found: $deviceId');
      }

      // Connect to the device
      await device
          .connect(license: License.free, autoConnect: false, mtu: null)
          .timeout(
            connectionTimeout,
            onTimeout: () {
              _logger.w(
                'Connection timeout after ${connectionTimeout.inSeconds} seconds',
              );
              _updateConnectionState(ConnectionState.disconnected);
              throw TimeoutException(
                'Failed to connect to device within ${connectionTimeout.inSeconds} seconds',
              );
            },
          );
      _connectedDevice = device;
      connectedDeviceRef = device;
      _connectedDeviceName = device.platformName.isNotEmpty
          ? device.platformName
          : 'Unknown Device';
      _isInDemoMode = false;

      // Discover services (retry once for devices that are slow to expose GATT)
      var services = await device.discoverServices();
      final hasHrService = services.any(
        (service) => _matchesUuid(service.uuid.str, bleHrServiceUuid),
      );
      if (!hasHrService) {
        _logger.w('Heart Rate Service not found; retrying discoverServices');
        _logDiscoveredServices(services);
        await Future<void>.delayed(const Duration(milliseconds: 600));
        services = await device.discoverServices();
      }

      // Verify Heart Rate Service is present
      final hrServiceRef = services.firstWhere(
        (service) => _matchesUuid(service.uuid.str, bleHrServiceUuid),
        orElse: () {
          _logDiscoveredServices(services);
          throw StateError('Heart Rate Service not found on device');
        },
      );

      // Verify we have the HR Measurement characteristic
      hrServiceRef.characteristics.firstWhere(
        (char) => _matchesUuid(char.uuid.str, bleHrMeasurementUuid),
        orElse: () =>
            throw StateError('Heart Rate Measurement characteristic not found'),
      );

      // Start monitoring battery level if the device supports it.
      await _startBatteryMonitoring(services: services);

      // Monitor device connection state
      _deviceStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          _updateConnectionState(ConnectionState.connected);
        } else if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Save connected device ID to settings
      await DatabaseService.instance.setSetting(
        'last_connected_device_id',
        deviceId,
      );

      // Update state to connected
      _updateConnectionState(ConnectionState.connected);
    } catch (e) {
      if (connectedDeviceRef != null) {
        try {
          await connectedDeviceRef.disconnect();
        } catch (disconnectError, stackTrace) {
          _logger.w(
            'Error during cleanup disconnect',
            error: disconnectError,
            stackTrace: stackTrace,
          );
        } finally {
          _connectedDevice = null;
          _connectedDeviceName = null;
          await _deviceStateSubscription?.cancel();
          _deviceStateSubscription = null;
          await _heartRateSubscription?.cancel();
          _heartRateSubscription = null;
          await _batteryLevelSubscription?.cancel();
          _batteryLevelSubscription = null;
          _updateBatteryLevel(null);
        }
      }
      _updateConnectionState(ConnectionState.disconnected);
      rethrow;
    }
  }

  /// Connects to demo mode.
  Future<void> _connectToDemoMode() async {
    try {
      // Update state to connecting
      _updateConnectionState(ConnectionState.connecting);

      // Stop any existing scan
      try {
        await stopScan();
      } catch (e, stackTrace) {
        // Log but don't fail - stopping scan might fail if it wasn't running
        _logger.w('Error stopping scan', error: e, stackTrace: stackTrace);
      }

      // Start demo mode service
      try {
        DemoModeService.instance.startDemoMode();
      } catch (e, stackTrace) {
        // Log the error - demo mode service might have issues
        _logger.e('Error starting demo mode', error: e, stackTrace: stackTrace);
        rethrow;
      }

      // Set demo mode flags
      _isInDemoMode = true;
      _connectedDevice = null;
      _connectedDeviceName = demoModeDeviceName;
      _updateBatteryLevel(100);

      // Save demo mode as last connected device
      try {
        await DatabaseService.instance.setSetting(
          'last_connected_device_id',
          demoModeDeviceId,
        );
      } catch (e, stackTrace) {
        // Log but don't fail - database error shouldn't prevent demo mode
        _logger.w(
          'Error saving demo mode preference',
          error: e,
          stackTrace: stackTrace,
        );
      }

      // Update state to connected
      _updateConnectionState(ConnectionState.connected);
    } catch (e) {
      _updateConnectionState(ConnectionState.disconnected);
      rethrow;
    }
  }

  /// Subscribes to heart rate notifications from the connected device or demo mode.
  ///
  /// Returns a stream of BPM (beats per minute) values as integers.
  /// The stream will emit values as they arrive (typically every 1-2 seconds).
  ///
  /// For real devices, parses the BLE Heart Rate Measurement format:
  /// - Byte 0: Flags (bit 0 = 0 for uint8, 1 for uint16)
  /// - Byte 1: HR value (uint8) OR Bytes 1-2: HR value (uint16 little-endian)
  ///
  /// For demo mode, streams simulated values from [DemoModeService].
  ///
  /// Throws [StateError] if no device is connected and not in demo mode.
  /// Throws [StateError] if Heart Rate Service or characteristic is not found.
  Stream<int> subscribeToHeartRate() async* {
    // Check if we're in demo mode
    if (_isInDemoMode) {
      // Yield directly from demo mode stream - simpler and more reliable
      // than routing through _heartRateController
      await for (final bpm in DemoModeService.instance.getDemoModeStream()) {
        yield bpm;
      }
      return;
    }

    if (_connectedDevice == null) {
      throw StateError('No device connected');
    }

    try {
      await _startHeartRateNotifications();

      // Yield values from the heart rate stream
      await for (final bpm in _heartRateController.stream) {
        yield bpm;
      }
    } catch (e, stackTrace) {
      // Log error for debugging - this is acceptable for production
      _logger.e(
        'Error subscribing to heart rate',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Ensures heart rate notifications are active after reconnection.
  ///
  /// Re-registers for HR measurement notifications so downstream listeners
  /// (e.g., heartRateProvider) continue receiving BPM updates.
  Future<void> restartHeartRateStream() async {
    if (_isInDemoMode) {
      // Demo mode stream is continuous; nothing to restart.
      return;
    }
    if (_connectedDevice == null) return;

    try {
      await _startHeartRateNotifications();
      await _startBatteryMonitoring();
    } catch (e, stackTrace) {
      _logger.w(
        'Error restarting heart rate notifications after reconnection',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sets up heart rate notifications on the connected device.
  Future<void> _startHeartRateNotifications() async {
    await _heartRateSubscription?.cancel();
    _heartRateSubscription = null;

    // Get services
    final services = await _connectedDevice!.discoverServices();

    // Find Heart Rate Service
    final hrService = services.firstWhere(
      (service) => _matchesUuid(service.uuid.str, bleHrServiceUuid),
      orElse: () => throw StateError('Heart Rate Service not found'),
    );

    // Find HR Measurement characteristic
    final hrCharacteristic = hrService.characteristics.firstWhere(
      (char) => _matchesUuid(char.uuid.str, bleHrMeasurementUuid),
      orElse: () =>
          throw StateError('Heart Rate Measurement characteristic not found'),
    );

    // Enable notifications
    await hrCharacteristic.setNotifyValue(true);

    // Listen to characteristic value changes using lastValueStream
    _heartRateSubscription = hrCharacteristic.lastValueStream.listen((value) {
      if (value.isNotEmpty) {
        try {
          final bpm = parseHeartRateValue(value);
          _heartRateController.add(bpm);
        } catch (e, stackTrace) {
          // Log parsing error but don't crash - this is acceptable for production
          _logger.w(
            'Error parsing heart rate value',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
    });
  }

  Future<void> _startBatteryMonitoring({List? services}) async {
    await _batteryLevelSubscription?.cancel();
    _batteryLevelSubscription = null;

    if (_isInDemoMode) {
      _updateBatteryLevel(100);
      return;
    }

    if (_connectedDevice == null) {
      _updateBatteryLevel(null);
      return;
    }

    try {
      final serviceList =
          services ?? await _connectedDevice!.discoverServices();
      final batteryService = serviceList.firstWhere(
        (service) => _matchesUuid(service.uuid.str, bleBatteryServiceUuid),
        orElse: () => throw StateError('Battery Service not found'),
      );

      final batteryCharacteristic = batteryService.characteristics.firstWhere(
        (char) => _matchesUuid(char.uuid.str, bleBatteryLevelUuid),
        orElse: () =>
            throw StateError('Battery Level characteristic not found'),
      );

      if (batteryCharacteristic.properties.read) {
        final value = await batteryCharacteristic.read();
        _updateBatteryLevel(_parseBatteryLevel(value));
      } else {
        _updateBatteryLevel(null);
      }

      if (batteryCharacteristic.properties.notify ||
          batteryCharacteristic.properties.indicate) {
        await batteryCharacteristic.setNotifyValue(true);
        _batteryLevelSubscription = batteryCharacteristic.lastValueStream
            .listen((value) {
              _updateBatteryLevel(_parseBatteryLevel(value));
            });
      }
    } catch (e, stackTrace) {
      _logger.w(
        'Battery level not available',
        error: e,
        stackTrace: stackTrace,
      );
      _updateBatteryLevel(null);
    }
  }

  /// Parses a BLE Heart Rate Measurement value according to the BLE specification.
  ///
  /// Format:
  /// - Byte 0: Flags
  ///   - Bit 0: 0 = uint8 format, 1 = uint16 format
  /// - Byte 1: HR value (uint8) OR
  /// - Bytes 1-2: HR value (uint16 little-endian)
  ///
  /// [data] is the raw byte array from the BLE characteristic.
  /// Returns the heart rate in beats per minute.
  ///
  /// Throws [FormatException] if data format is invalid.
  int parseHeartRateValue(List<int> data) {
    if (data.isEmpty) {
      throw const FormatException('Heart rate data is empty');
    }

    final flags = data[0];
    final isUint16 = (flags & 0x01) != 0;

    if (isUint16) {
      // uint16 format (little-endian)
      if (data.length < 3) {
        throw const FormatException(
          'Insufficient data for uint16 heart rate value',
        );
      }
      // Little-endian: least significant byte first
      return data[1] | (data[2] << 8);
    } else {
      // uint8 format
      if (data.length < 2) {
        throw const FormatException(
          'Insufficient data for uint8 heart rate value',
        );
      }
      return data[1];
    }
  }

  /// Disconnects from the currently connected device or demo mode.
  ///
  /// This performs a clean disconnection:
  /// - Stops heart rate notifications
  /// - Closes the connection
  /// - Clears saved device preference (manual disconnect)
  Future<void> disconnect() async {
    // Handle demo mode disconnect
    if (_isInDemoMode) {
      await _demoModeSubscription?.cancel();
      _demoModeSubscription = null;
      DemoModeService.instance.stopDemoMode();
      _isInDemoMode = false;
      _connectedDeviceName = null;
      _updateBatteryLevel(null);

      // Clear saved device (manual disconnect)
      await DatabaseService.instance.setSetting('last_connected_device_id', '');

      _updateConnectionState(ConnectionState.disconnected);
      return;
    }

    if (_connectedDevice == null) return;

    try {
      // Stop heart rate notifications
      await _heartRateSubscription?.cancel();
      _heartRateSubscription = null;
      await _batteryLevelSubscription?.cancel();
      _batteryLevelSubscription = null;

      // Stop monitoring device state
      await _deviceStateSubscription?.cancel();
      _deviceStateSubscription = null;

      // Disconnect from device
      await _connectedDevice!.disconnect();

      // Clear saved device (manual disconnect)
      await DatabaseService.instance.setSetting('last_connected_device_id', '');

      _connectedDevice = null;
      _connectedDeviceName = null;
      _updateBatteryLevel(null);
      _updateConnectionState(ConnectionState.disconnected);
    } catch (e, stackTrace) {
      // Log error for debugging - this is acceptable for production
      _logger.e('Error during disconnect', error: e, stackTrace: stackTrace);
      _connectedDevice = null;
      _connectedDeviceName = null;
      _updateBatteryLevel(null);
      _updateConnectionState(ConnectionState.disconnected);
    }
  }

  /// Monitors the connection state changes.
  ///
  /// Returns a stream of [ConnectionState] values.
  Stream<ConnectionState> monitorConnectionState() {
    if (this is _TestBluetoothService) {
      return (this as _TestBluetoothService)._connectionStateStream ??
          _connectionStateController.stream;
    }
    return _connectionStateController.stream;
  }

  /// Monitors the battery level updates.
  Stream<int?> monitorBatteryLevel() async* {
    yield _batteryLevel;
    yield* _batteryLevelController.stream;
  }

  /// Updates the connection state and notifies listeners.
  void _updateConnectionState(ConnectionState newState) {
    _connectionState = newState;
    _connectionStateController.add(newState);
  }

  /// Sets the connection state to reconnecting.
  ///
  /// This is called by the reconnection handler when attempting to reconnect.
  void setReconnecting() {
    _updateConnectionState(ConnectionState.reconnecting);
  }

  /// Handles unexpected disconnection from device.
  void _handleDisconnection() {
    _heartRateSubscription?.cancel();
    _heartRateSubscription = null;
    _batteryLevelSubscription?.cancel();
    _batteryLevelSubscription = null;
    _deviceStateSubscription?.cancel();
    _deviceStateSubscription = null;
    _connectedDevice = null;
    _updateBatteryLevel(null);
    _updateConnectionState(ConnectionState.disconnected);
  }

  /// Finds a device by its ID from previously scanned devices.
  ///
  /// Returns the device or null if not found.
  Future<BluetoothDevice?> _findDeviceById(String deviceId) async {
    try {
      final scannedDevice = _scannedDevices[deviceId];
      if (scannedDevice != null) {
        return scannedDevice;
      }

      // Get connected devices
      final connectedDevices = FlutterBluePlus.connectedDevices;
      for (var device in connectedDevices) {
        if (device.remoteId.str == deviceId) return device;
      }

      // Get system devices (bonded on Android)
      final systemDevices = await FlutterBluePlus.systemDevices([
        Guid(bleHrServiceUuid),
      ]);
      for (var device in systemDevices) {
        if (device.remoteId.str == deviceId) return device;
      }

      // Device not found in cache, caller should handle appropriately
      return null;
    } catch (e, stackTrace) {
      // Log error for debugging - this is acceptable for production
      _logger.w('Error finding device', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  void _logDiscoveredServices(List services) {
    final serviceSummaries = services.map((service) {
      final characteristics = service.characteristics
          .map((char) => _shortUuid(char.uuid.str))
          .toList();
      return '${_shortUuid(service.uuid.str)} '
          'chars=$characteristics';
    }).toList();
    _logger.d('Discovered services: $serviceSummaries');
  }

  String _shortUuid(String uuid) {
    final hex = uuid.toLowerCase().replaceAll('-', '');
    if (hex.length >= 8) {
      return hex.substring(4, 8);
    }
    return hex;
  }

  bool _matchesUuid(String actual, String expected) {
    final actualShort = _shortUuid(actual);
    final expectedShort = _shortUuid(expected);
    return actualShort == expectedShort ||
        actual.toLowerCase() == expected.toLowerCase();
  }

  int? _parseBatteryLevel(List<int> value) {
    if (value.isEmpty) return null;
    final raw = value.first;
    if (raw == 0xFF) return null;
    if (raw < 0) return 0;
    if (raw > 100) return 100;
    return raw;
  }

  void _updateBatteryLevel(int? level) {
    _batteryLevel = level;
    _batteryLevelController.add(level);
  }

  bool _isLikelyHrDevice(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    const keywords = [
      'coospo',
      'polar',
      'wahoo',
      'garmin',
      'tickr',
      'h9z',
      'h10',
      'h9',
      'hrm',
      'heart',
    ];
    return keywords.any(normalized.contains);
  }

  @visibleForTesting
  void cacheScannedDeviceForTest(BluetoothDevice device) {
    _scannedDevices[device.remoteId.str] = device;
  }

  @visibleForTesting
  void clearScannedDevicesForTest() {
    _scannedDevices.clear();
  }

  @visibleForTesting
  Future<BluetoothDevice?> findDeviceByIdForTest(String deviceId) async {
    return _findDeviceById(deviceId);
  }

  /// Disposes of resources and closes streams.
  ///
  /// Should be called when the service is no longer needed.
  Future<void> dispose() async {
    await stopScan();
    await disconnect();
    await _scanResultsController.close();
    await _heartRateController.close();
    await _connectionStateController.close();
    await _batteryLevelController.close();
  }
}

/// Lightweight test double to avoid platform channels in integration tests.
class _TestBluetoothService extends BluetoothService {
  _TestBluetoothService({
    Stream<ConnectionState>? connectionStateStream,
    this.onConnect,
    this.onRestartHeartRate,
  }) : _connectionStateStream = connectionStateStream,
       super._internal();

  final Stream<ConnectionState>? _connectionStateStream;
  final Future<void> Function(String deviceId)? onConnect;
  final Future<void> Function()? onRestartHeartRate;

  Future<void> _handleTestConnect(String deviceId) async {
    _updateConnectionState(ConnectionState.connecting);
    try {
      final connectFuture = onConnect != null
          ? onConnect!(deviceId)
          : Future<void>.value();

      await connectFuture.timeout(
        BluetoothService.connectionTimeout,
        onTimeout: () {
          _updateConnectionState(ConnectionState.disconnected);
          throw TimeoutException(
            'Failed to connect to device within '
            '${BluetoothService.connectionTimeout.inSeconds} seconds',
          );
        },
      );

      _connectedDeviceName = deviceId;
      _updateConnectionState(ConnectionState.connected);
    } catch (e) {
      _updateConnectionState(ConnectionState.disconnected);
      rethrow;
    }
  }

  @override
  Future<void> restartHeartRateStream() async {
    if (onRestartHeartRate != null) {
      await onRestartHeartRate!();
    }
  }
}
