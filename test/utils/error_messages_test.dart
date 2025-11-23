import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/utils/error_messages.dart';

void main() {
  group('Error Message Constants', () {
    test('errorBluetoothDisabled is defined', () {
      expect(errorBluetoothDisabled, isNotEmpty);
      expect(errorBluetoothDisabled, contains('Bluetooth'));
    });

    test('errorPermissionDenied is defined', () {
      expect(errorPermissionDenied, isNotEmpty);
      expect(errorPermissionDenied, contains('permission'));
    });

    test('errorNoDevicesFound is defined', () {
      expect(errorNoDevicesFound, isNotEmpty);
      expect(errorNoDevicesFound, contains('heart rate'));
    });

    test('errorConnectionTimeout is defined', () {
      expect(errorConnectionTimeout, isNotEmpty);
      expect(errorConnectionTimeout, contains('connect'));
    });

    test('errorServiceNotFound is defined', () {
      expect(errorServiceNotFound, isNotEmpty);
      expect(errorServiceNotFound, contains('heart rate'));
    });

    test('errorGeneric is defined', () {
      expect(errorGeneric, isNotEmpty);
    });

    test('errorReconnectionFailed is defined', () {
      expect(errorReconnectionFailed, isNotEmpty);
      expect(errorReconnectionFailed, contains('Connection'));
    });

    test('errorLocationPermissionRequired is defined', () {
      expect(errorLocationPermissionRequired, isNotEmpty);
      expect(errorLocationPermissionRequired, contains('Location'));
    });

    test('errorUnexpectedDisconnect is defined', () {
      expect(errorUnexpectedDisconnect, isNotEmpty);
      expect(errorUnexpectedDisconnect, contains('lost'));
    });
  });

  group('getConnectionTimeoutMessage', () {
    test('includes device name in message', () {
      final message = getConnectionTimeoutMessage('Polar H10');

      expect(message, contains('Polar H10'));
      expect(message, contains('connect'));
    });

    test('handles empty device name', () {
      final message = getConnectionTimeoutMessage('');

      expect(message, contains('connect'));
    });

    test('handles device name with special characters', () {
      final message = getConnectionTimeoutMessage("Device's Name");

      expect(message, contains("Device's Name"));
    });
  });

  group('getReconnectionFailedMessage', () {
    test('includes attempt count in message', () {
      final message = getReconnectionFailedMessage(5);

      expect(message, contains('5'));
      expect(message, contains('reconnect'));
    });

    test('works with single attempt', () {
      final message = getReconnectionFailedMessage(1);

      expect(message, contains('1'));
    });

    test('works with large attempt count', () {
      final message = getReconnectionFailedMessage(100);

      expect(message, contains('100'));
    });
  });

  group('getUserFriendlyErrorMessage', () {
    test('returns bluetooth disabled message for bluetooth off error', () {
      final error = Exception('Bluetooth is off');
      final message = getUserFriendlyErrorMessage(error);

      expect(message, equals(errorBluetoothDisabled));
    });

    test('returns permission denied message for permission error', () {
      final error = Exception('Permission denied');
      final message = getUserFriendlyErrorMessage(error);

      expect(message, equals(errorPermissionDenied));
    });

    test('returns generic timeout message when no device name', () {
      final error = Exception('Connection timeout occurred');
      final message = getUserFriendlyErrorMessage(error);

      expect(message, equals(errorConnectionTimeout));
    });

    test('returns device-specific timeout message with device name', () {
      final error = Exception('Timeout');
      final message = getUserFriendlyErrorMessage(
        error,
        deviceName: 'Garmin HRM',
      );

      expect(message, contains('Garmin HRM'));
    });

    test('returns service not found message for service error', () {
      final error = Exception('Heart rate service not found');
      final message = getUserFriendlyErrorMessage(error);

      expect(message, equals(errorServiceNotFound));
    });

    test('returns disconnect message for disconnect error', () {
      final error = Exception('Device disconnected');
      final message = getUserFriendlyErrorMessage(error);

      expect(message, equals(errorUnexpectedDisconnect));
    });

    test('returns generic message for unknown error', () {
      final error = Exception('Some random error');
      final message = getUserFriendlyErrorMessage(error);

      expect(message, equals(errorGeneric));
    });

    test('handles non-Exception objects', () {
      final message = getUserFriendlyErrorMessage('String error');

      expect(message, isNotEmpty);
    });

    test('case insensitive matching', () {
      final error1 = Exception('BLUETOOTH IS OFF');
      final error2 = Exception('permission DENIED');

      expect(
        getUserFriendlyErrorMessage(error1),
        equals(errorBluetoothDisabled),
      );
      expect(
        getUserFriendlyErrorMessage(error2),
        equals(errorPermissionDenied),
      );
    });
  });

  group('BluetoothErrorType', () {
    test('all enum values are defined', () {
      expect(BluetoothErrorType.values, hasLength(9));
      expect(
        BluetoothErrorType.values,
        contains(BluetoothErrorType.bluetoothDisabled),
      );
      expect(
        BluetoothErrorType.values,
        contains(BluetoothErrorType.permissionDenied),
      );
      expect(
        BluetoothErrorType.values,
        contains(BluetoothErrorType.noDevicesFound),
      );
      expect(
        BluetoothErrorType.values,
        contains(BluetoothErrorType.connectionTimeout),
      );
      expect(
        BluetoothErrorType.values,
        contains(BluetoothErrorType.serviceNotFound),
      );
      expect(
        BluetoothErrorType.values,
        contains(BluetoothErrorType.unexpectedDisconnect),
      );
      expect(
        BluetoothErrorType.values,
        contains(BluetoothErrorType.reconnectionFailed),
      );
      expect(
        BluetoothErrorType.values,
        contains(BluetoothErrorType.locationPermissionRequired),
      );
      expect(BluetoothErrorType.values, contains(BluetoothErrorType.unknown));
    });
  });

  group('getMessageForErrorType', () {
    test('returns correct message for bluetoothDisabled', () {
      final message = getMessageForErrorType(
        BluetoothErrorType.bluetoothDisabled,
      );
      expect(message, equals(errorBluetoothDisabled));
    });

    test('returns correct message for permissionDenied', () {
      final message = getMessageForErrorType(
        BluetoothErrorType.permissionDenied,
      );
      expect(message, equals(errorPermissionDenied));
    });

    test('returns correct message for noDevicesFound', () {
      final message = getMessageForErrorType(BluetoothErrorType.noDevicesFound);
      expect(message, equals(errorNoDevicesFound));
    });

    test(
      'returns generic message for connectionTimeout without device name',
      () {
        final message = getMessageForErrorType(
          BluetoothErrorType.connectionTimeout,
        );
        expect(message, equals(errorConnectionTimeout));
      },
    );

    test(
      'returns device-specific message for connectionTimeout with device name',
      () {
        final message = getMessageForErrorType(
          BluetoothErrorType.connectionTimeout,
          deviceName: 'Polar H10',
        );
        expect(message, contains('Polar H10'));
      },
    );

    test('returns correct message for serviceNotFound', () {
      final message = getMessageForErrorType(
        BluetoothErrorType.serviceNotFound,
      );
      expect(message, equals(errorServiceNotFound));
    });

    test('returns correct message for unexpectedDisconnect', () {
      final message = getMessageForErrorType(
        BluetoothErrorType.unexpectedDisconnect,
      );
      expect(message, equals(errorUnexpectedDisconnect));
    });

    test('returns correct message for reconnectionFailed', () {
      final message = getMessageForErrorType(
        BluetoothErrorType.reconnectionFailed,
      );
      expect(message, equals(errorReconnectionFailed));
    });

    test('returns correct message for locationPermissionRequired', () {
      final message = getMessageForErrorType(
        BluetoothErrorType.locationPermissionRequired,
      );
      expect(message, equals(errorLocationPermissionRequired));
    });

    test('returns correct message for unknown', () {
      final message = getMessageForErrorType(BluetoothErrorType.unknown);
      expect(message, equals(errorGeneric));
    });
  });
}
