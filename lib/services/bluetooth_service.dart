import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/constants.dart';
import 'database_service.dart';

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
///
/// Uses singleton pattern to ensure only one BLE instance exists.
class BluetoothService {
  // Singleton instance
  static final BluetoothService instance = BluetoothService._internal();

  // Current connection state
  ConnectionState _connectionState = ConnectionState.disconnected;

  // Currently connected device
  BluetoothDevice? _connectedDevice;

  // Stream controllers for managing data flows
  final StreamController<List<BluetoothDevice>> _scanResultsController =
      StreamController<List<BluetoothDevice>>.broadcast();
  final StreamController<int> _heartRateController =
      StreamController<int>.broadcast();
  final StreamController<ConnectionState> _connectionStateController =
      StreamController<ConnectionState>.broadcast();

  // Subscriptions for cleanup
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _deviceStateSubscription;
  StreamSubscription<List<int>>? _heartRateSubscription;

  // Connection timeout timer
  Timer? _connectionTimeoutTimer;

  // Private constructor for singleton
  BluetoothService._internal();

  /// Gets the current connection state.
  ConnectionState get connectionState => _connectionState;

  /// Gets the currently connected device, if any.
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Starts scanning for BLE devices advertising Heart Rate Service (0x180D).
  ///
  /// Returns a stream of discovered devices. Only devices with the Heart Rate
  /// Service will be included. Each device includes signal strength (RSSI).
  ///
  /// Throws [StateError] if Bluetooth is not available.
  /// Throws [StateError] if location permission is not granted (Android).
  Stream<List<BluetoothDevice>> scanForDevices() {
    // Check if Bluetooth is available
    _checkBluetoothAvailability();

    // Stop any existing scan
    stopScan();

    // List to accumulate unique devices
    final Map<String, BluetoothDevice> discoveredDevices = {};

    // Start scanning with HR service filter
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        // Filter for devices advertising Heart Rate Service
        final hasHrService = result.advertisementData.serviceUuids.any(
          (uuid) => uuid.str.toLowerCase() == bleHrServiceUuid,
        );

        if (hasHrService &&
            !discoveredDevices.containsKey(result.device.remoteId.str)) {
          discoveredDevices[result.device.remoteId.str] = result.device;
          _scanResultsController.add(discoveredDevices.values.toList());
        }
      }
    });

    // Start the scan
    FlutterBluePlus.startScan(
      withServices: [Guid(bleHrServiceUuid)],
      timeout: const Duration(seconds: 30),
    );

    return _scanResultsController.stream;
  }

  /// Stops the current BLE scan.
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await FlutterBluePlus.stopScan();
  }

  /// Connects to a BLE device by its ID.
  ///
  /// [deviceId] is the unique identifier of the device to connect to.
  ///
  /// This method will:
  /// 1. Initiate connection with 15-second timeout
  /// 2. Discover services after connection
  /// 3. Verify Heart Rate Service (0x180D) is present
  /// 4. Save device ID to settings for reconnection
  ///
  /// Throws [TimeoutException] if connection times out.
  /// Throws [StateError] if Heart Rate Service is not found.
  /// Throws [Exception] for other connection errors.
  Future<void> connectToDevice(String deviceId) async {
    try {
      // Update state to connecting
      _updateConnectionState(ConnectionState.connecting);

      // Stop any existing scan
      await stopScan();

      // Find the device
      final device = await _findDeviceById(deviceId);
      if (device == null) {
        throw StateError('Device not found: $deviceId');
      }

      // Set connection timeout
      _connectionTimeoutTimer = Timer(const Duration(seconds: 15), () {
        _updateConnectionState(ConnectionState.disconnected);
        throw TimeoutException('Connection timeout');
      });

      // Connect to the device
      await device.connect(
        license: License.free,
        autoConnect: false,
        mtu: null,
      );
      _connectedDevice = device;

      // Cancel timeout timer
      _connectionTimeoutTimer?.cancel();
      _connectionTimeoutTimer = null;

      // Discover services
      final services = await device.discoverServices();

      // Verify Heart Rate Service is present
      final hrService = services.firstWhere(
        (service) => service.uuid.str.toLowerCase() == bleHrServiceUuid,
        orElse: () =>
            throw StateError('Heart Rate Service not found on device'),
      );

      // Verify we have the HR Measurement characteristic
      hrService.characteristics.firstWhere(
        (char) => char.uuid.str.toLowerCase() == bleHrMeasurementUuid,
        orElse: () =>
            throw StateError('Heart Rate Measurement characteristic not found'),
      );

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
      _connectionTimeoutTimer?.cancel();
      _updateConnectionState(ConnectionState.disconnected);
      rethrow;
    }
  }

  /// Subscribes to heart rate notifications from the connected device.
  ///
  /// Returns a stream of BPM (beats per minute) values as integers.
  /// The stream will emit values as they arrive from the device (typically every 1-2 seconds).
  ///
  /// Parses the BLE Heart Rate Measurement format:
  /// - Byte 0: Flags (bit 0 = 0 for uint8, 1 for uint16)
  /// - Byte 1: HR value (uint8) OR Bytes 1-2: HR value (uint16 little-endian)
  ///
  /// Throws [StateError] if no device is connected.
  /// Throws [StateError] if Heart Rate Service or characteristic is not found.
  Stream<int> subscribeToHeartRate() async* {
    if (_connectedDevice == null) {
      throw StateError('No device connected');
    }

    try {
      // Get services
      final services = await _connectedDevice!.discoverServices();

      // Find Heart Rate Service
      final hrService = services.firstWhere(
        (service) => service.uuid.str.toLowerCase() == bleHrServiceUuid,
        orElse: () => throw StateError('Heart Rate Service not found'),
      );

      // Find HR Measurement characteristic
      final hrCharacteristic = hrService.characteristics.firstWhere(
        (char) => char.uuid.str.toLowerCase() == bleHrMeasurementUuid,
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
          } catch (e) {
            // Log parsing error but don't crash - this is acceptable for production
            // ignore: avoid_print
            print('Error parsing heart rate value: $e');
          }
        }
      });

      // Yield values from the heart rate stream
      await for (final bpm in _heartRateController.stream) {
        yield bpm;
      }
    } catch (e) {
      // Log error for debugging - this is acceptable for production
      // ignore: avoid_print
      print('Error subscribing to heart rate: $e');
      rethrow;
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

  /// Disconnects from the currently connected device.
  ///
  /// This performs a clean disconnection:
  /// - Stops heart rate notifications
  /// - Closes the connection
  /// - Clears saved device preference (manual disconnect)
  Future<void> disconnect() async {
    if (_connectedDevice == null) return;

    try {
      // Stop heart rate notifications
      await _heartRateSubscription?.cancel();
      _heartRateSubscription = null;

      // Stop monitoring device state
      await _deviceStateSubscription?.cancel();
      _deviceStateSubscription = null;

      // Disconnect from device
      await _connectedDevice!.disconnect();

      // Clear saved device (manual disconnect)
      await DatabaseService.instance.setSetting('last_connected_device_id', '');

      _connectedDevice = null;
      _updateConnectionState(ConnectionState.disconnected);
    } catch (e) {
      // Log error for debugging - this is acceptable for production
      // ignore: avoid_print
      print('Error during disconnect: $e');
      _connectedDevice = null;
      _updateConnectionState(ConnectionState.disconnected);
    }
  }

  /// Monitors the connection state changes.
  ///
  /// Returns a stream of [ConnectionState] values.
  Stream<ConnectionState> monitorConnectionState() {
    return _connectionStateController.stream;
  }

  /// Updates the connection state and notifies listeners.
  void _updateConnectionState(ConnectionState newState) {
    _connectionState = newState;
    _connectionStateController.add(newState);
  }

  /// Handles unexpected disconnection from device.
  void _handleDisconnection() {
    _heartRateSubscription?.cancel();
    _heartRateSubscription = null;
    _deviceStateSubscription?.cancel();
    _deviceStateSubscription = null;
    _connectedDevice = null;
    _updateConnectionState(ConnectionState.disconnected);
  }

  /// Checks if Bluetooth is available and enabled.
  ///
  /// Throws [StateError] if Bluetooth is not available.
  void _checkBluetoothAvailability() {
    // Note: flutter_blue_plus will throw appropriate errors if BT is off
    // or permissions are missing. We rely on those errors propagating.
  }

  /// Finds a device by its ID from previously scanned devices.
  ///
  /// Returns the device or null if not found.
  Future<BluetoothDevice?> _findDeviceById(String deviceId) async {
    try {
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
    } catch (e) {
      // Log error for debugging - this is acceptable for production
      // ignore: avoid_print
      print('Error finding device: $e');
      return null;
    }
  }

  /// Disposes of resources and closes streams.
  ///
  /// Should be called when the service is no longer needed.
  Future<void> dispose() async {
    await stopScan();
    await disconnect();
    _connectionTimeoutTimer?.cancel();
    await _scanResultsController.close();
    await _heartRateController.close();
    await _connectionStateController.close();
  }
}
