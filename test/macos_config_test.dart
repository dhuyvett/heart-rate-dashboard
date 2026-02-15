// Tests for verifying macOS configuration for Heart Rate Dashboard.
//
// These tests verify:
// - Info.plist contains Bluetooth usage descriptions
// - Entitlements include Bluetooth device access

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('macOS Configuration', () {
    test('Info.plist contains Bluetooth usage description', () {
      final infoPlistFile = File('macos/Runner/Info.plist');
      expect(
        infoPlistFile.existsSync(),
        isTrue,
        reason: 'Info.plist file should exist',
      );

      final content = infoPlistFile.readAsStringSync();
      expect(
        content.contains('<key>NSBluetoothAlwaysUsageDescription</key>'),
        isTrue,
        reason:
            'Info.plist should contain NSBluetoothAlwaysUsageDescription key',
      );
      expect(
        content.contains(
          'Bluetooth access is required to connect to your heart rate monitor.',
        ),
        isTrue,
        reason: 'Bluetooth usage description should be present',
      );
    });

    test('Debug entitlements include Bluetooth device access', () {
      final entitlementsFile = File('macos/Runner/DebugProfile.entitlements');
      expect(
        entitlementsFile.existsSync(),
        isTrue,
        reason: 'DebugProfile.entitlements should exist',
      );

      final content = entitlementsFile.readAsStringSync();
      expect(
        content.contains('<key>com.apple.security.device.bluetooth</key>'),
        isTrue,
        reason: 'Debug entitlements should include Bluetooth device access',
      );
    });

    test('Release entitlements include Bluetooth device access', () {
      final entitlementsFile = File('macos/Runner/Release.entitlements');
      expect(
        entitlementsFile.existsSync(),
        isTrue,
        reason: 'Release.entitlements should exist',
      );

      final content = entitlementsFile.readAsStringSync();
      expect(
        content.contains('<key>com.apple.security.device.bluetooth</key>'),
        isTrue,
        reason: 'Release entitlements should include Bluetooth device access',
      );
    });
  });
}
