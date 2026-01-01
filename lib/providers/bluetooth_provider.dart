import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bluetooth_service.dart';

/// Information about the current Bluetooth connection state.
class BluetoothConnectionInfo {
  /// The current connection state.
  final ConnectionState connectionState;

  /// The name of the currently connected device.
  /// Null if no device is connected.
  final String? deviceName;

  /// Error message if connection failed.
  /// Null if no error occurred.
  final String? errorMessage;

  /// Creates a Bluetooth connection info instance.
  const BluetoothConnectionInfo({
    required this.connectionState,
    this.deviceName,
    this.errorMessage,
  });

  /// Creates a copy with updated fields.
  BluetoothConnectionInfo copyWith({
    ConnectionState? connectionState,
    String? deviceName,
    String? errorMessage,
  }) {
    return BluetoothConnectionInfo(
      connectionState: connectionState ?? this.connectionState,
      deviceName: deviceName ?? this.deviceName,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BluetoothConnectionInfo &&
        other.connectionState == connectionState &&
        other.deviceName == deviceName &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(connectionState, deviceName, errorMessage);

  @override
  String toString() {
    return 'BluetoothConnectionInfo(connectionState: $connectionState, '
        'deviceName: $deviceName, errorMessage: $errorMessage)';
  }
}

/// Provider for Bluetooth connection state.
///
/// Streams the current connection state, device name, and any error messages.
final bluetoothConnectionProvider = StreamProvider<BluetoothConnectionInfo>((
  ref,
) async* {
  final bluetoothService = BluetoothService.instance;

  // Initial state
  yield BluetoothConnectionInfo(
    connectionState: bluetoothService.connectionState,
    deviceName: bluetoothService.connectedDevice?.platformName,
  );

  // Stream connection state changes
  await for (final state in bluetoothService.monitorConnectionState()) {
    yield BluetoothConnectionInfo(
      connectionState: state,
      deviceName: bluetoothService.connectedDevice?.platformName,
    );
  }
});

/// Provider for the connected device battery level (0-100).
///
/// Emits null when the battery service is unavailable.
final batteryLevelProvider = StreamProvider<int?>((ref) async* {
  final bluetoothService = BluetoothService.instance;
  yield* bluetoothService.monitorBatteryLevel();
});
