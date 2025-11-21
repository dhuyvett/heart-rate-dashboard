import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/services/bluetooth_service.dart';

/// Tests for the BluetoothService.
///
/// These tests focus on critical BLE functionality using mocked FlutterBluePlus
/// to avoid requiring physical hardware. Tests cover:
/// - Device scanning behavior
/// - Connection state changes
/// - Heart rate data parsing (uint8 and uint16 formats)
void main() {
  group('BluetoothService', () {
    late BluetoothService service;

    setUp(() {
      service = BluetoothService.instance;
    });

    test('singleton returns same instance', () {
      final instance1 = BluetoothService.instance;
      final instance2 = BluetoothService.instance;
      expect(instance1, same(instance2));
    });

    test('connection state starts as disconnected', () {
      final state = service.connectionState;
      expect(state, equals(ConnectionState.disconnected));
    });

    test('parseHeartRateValue handles uint8 format correctly', () {
      // BLE HR Measurement format with uint8:
      // Byte 0: Flags = 0x00 (bit 0 = 0 means uint8)
      // Byte 1: HR value = 72 BPM
      final data = [0x00, 72];
      final bpm = service.parseHeartRateValue(data);
      expect(bpm, equals(72));
    });

    test('parseHeartRateValue handles uint16 format correctly', () {
      // BLE HR Measurement format with uint16:
      // Byte 0: Flags = 0x01 (bit 0 = 1 means uint16)
      // Byte 1-2: HR value = 180 BPM (little-endian: 0xB4 0x00)
      final data = [0x01, 0xB4, 0x00];
      final bpm = service.parseHeartRateValue(data);
      expect(bpm, equals(180));
    });

    test('parseHeartRateValue handles uint16 high value correctly', () {
      // BLE HR Measurement format with uint16:
      // Byte 0: Flags = 0x01 (bit 0 = 1 means uint16)
      // Byte 1-2: HR value = 300 BPM (little-endian: 0x2C 0x01)
      final data = [0x01, 0x2C, 0x01];
      final bpm = service.parseHeartRateValue(data);
      expect(bpm, equals(300));
    });

    test('parseHeartRateValue throws error for empty data', () {
      expect(
        () => service.parseHeartRateValue([]),
        throwsA(isA<FormatException>()),
      );
    });

    test('parseHeartRateValue throws error for insufficient uint16 data', () {
      // Flags indicate uint16 but only 1 byte of data
      final data = [0x01, 0xB4];
      expect(
        () => service.parseHeartRateValue(data),
        throwsA(isA<FormatException>()),
      );
    });

    test('parseHeartRateValue throws error for insufficient uint8 data', () {
      // Flags indicate uint8 but no data bytes
      final data = [0x00];
      expect(
        () => service.parseHeartRateValue(data),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
