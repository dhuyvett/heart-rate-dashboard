/// User-friendly error messages for the workout tracker app.
///
/// All error messages are designed to be:
/// - Simple and non-technical
/// - Actionable (tell the user what to do)
/// - Context-specific where possible
///
/// Use these constants instead of generic or technical error messages
/// to maintain consistency and provide a better user experience.
library;

/// Error message when Bluetooth is disabled on the device.
const String errorBluetoothDisabled =
    'Bluetooth is turned off. Please enable it in your device settings.';

/// Error message when Bluetooth permission is denied.
const String errorPermissionDenied =
    'Bluetooth permission is required to connect to heart rate monitors.';

/// Error message when no devices are found during scanning.
const String errorNoDevicesFound =
    'No heart rate monitors found. Make sure your device is turned on and in range.';

/// Error message when connection to a device times out.
///
/// Use [getConnectionTimeoutMessage] to include the device name.
const String errorConnectionTimeout =
    'Could not connect to the device. Make sure it\'s turned on and nearby.';

/// Error message when the Heart Rate Service is not found on the device.
const String errorServiceNotFound =
    'This device doesn\'t support heart rate monitoring.';

/// Generic error message when something unexpected happens.
const String errorGeneric = 'Something went wrong. Please try again.';

/// Error message when reconnection fails after all attempts.
const String errorReconnectionFailed =
    'Connection lost. Could not reconnect to the device.';

/// Error message when location permission is required (Android).
const String errorLocationPermissionRequired =
    'Location permission is required for Bluetooth scanning on Android.';

/// Error message when the device disconnected unexpectedly.
const String errorUnexpectedDisconnect =
    'Connection to the device was lost unexpectedly.';

/// Returns a connection timeout error message with the device name.
///
/// [deviceName] is the name of the device that failed to connect.
String getConnectionTimeoutMessage(String deviceName) {
  return 'Could not connect to $deviceName. Make sure it\'s turned on and nearby.';
}

/// Returns a reconnection failure message with attempt count.
///
/// [attempts] is the number of reconnection attempts made.
String getReconnectionFailedMessage(int attempts) {
  return 'Could not reconnect after $attempts attempts. '
      'The device may be out of range or turned off.';
}

/// Returns a user-friendly error message based on the exception type.
///
/// This function maps technical exceptions to user-friendly messages.
/// It handles common Bluetooth-related errors and provides appropriate
/// messages for each case.
///
/// [error] is the exception that occurred.
/// [deviceName] is optional and will be included in relevant messages.
String getUserFriendlyErrorMessage(Object error, {String? deviceName}) {
  final errorString = error.toString().toLowerCase();

  // Check for specific error patterns
  if (errorString.contains('bluetooth') && errorString.contains('off')) {
    return errorBluetoothDisabled;
  }

  if (errorString.contains('permission')) {
    return errorPermissionDenied;
  }

  if (errorString.contains('timeout')) {
    return deviceName != null
        ? getConnectionTimeoutMessage(deviceName)
        : errorConnectionTimeout;
  }

  if (errorString.contains('service not found') ||
      errorString.contains('heart rate service')) {
    return errorServiceNotFound;
  }

  if (errorString.contains('disconnect')) {
    return errorUnexpectedDisconnect;
  }

  // Return generic error for unknown cases
  return errorGeneric;
}

/// Exception types for categorizing Bluetooth errors.
enum BluetoothErrorType {
  /// Bluetooth is disabled on the device.
  bluetoothDisabled,

  /// Required permissions are not granted.
  permissionDenied,

  /// No devices were found during scanning.
  noDevicesFound,

  /// Connection to the device timed out.
  connectionTimeout,

  /// The Heart Rate Service was not found on the device.
  serviceNotFound,

  /// Connection was lost unexpectedly.
  unexpectedDisconnect,

  /// Reconnection attempts failed.
  reconnectionFailed,

  /// Location permission required (Android).
  locationPermissionRequired,

  /// Unknown or generic error.
  unknown,
}

/// Returns the user-friendly message for a given error type.
String getMessageForErrorType(BluetoothErrorType type, {String? deviceName}) {
  switch (type) {
    case BluetoothErrorType.bluetoothDisabled:
      return errorBluetoothDisabled;
    case BluetoothErrorType.permissionDenied:
      return errorPermissionDenied;
    case BluetoothErrorType.noDevicesFound:
      return errorNoDevicesFound;
    case BluetoothErrorType.connectionTimeout:
      return deviceName != null
          ? getConnectionTimeoutMessage(deviceName)
          : errorConnectionTimeout;
    case BluetoothErrorType.serviceNotFound:
      return errorServiceNotFound;
    case BluetoothErrorType.unexpectedDisconnect:
      return errorUnexpectedDisconnect;
    case BluetoothErrorType.reconnectionFailed:
      return errorReconnectionFailed;
    case BluetoothErrorType.locationPermissionRequired:
      return errorLocationPermissionRequired;
    case BluetoothErrorType.unknown:
      return errorGeneric;
  }
}
