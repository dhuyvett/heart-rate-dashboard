// Tests for verifying iOS configuration is correctly set up for "Heart Rate Dashboard".
//
// These tests verify:
// - Info.plist contains correct bundle names
// - Bundle identifier is correct in project.pbxproj
//
// Note: These are file-based tests that read the iOS configuration files
// directly rather than runtime tests.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iOS Configuration', () {
    test('Info.plist contains correct CFBundleDisplayName', () {
      final infoPlistFile = File('ios/Runner/Info.plist');
      expect(
        infoPlistFile.existsSync(),
        isTrue,
        reason: 'Info.plist file should exist',
      );

      final content = infoPlistFile.readAsStringSync();

      // Verify CFBundleDisplayName is set to Heart Rate Dashboard
      expect(
        content.contains('<key>CFBundleDisplayName</key>'),
        isTrue,
        reason: 'Info.plist should contain CFBundleDisplayName key',
      );
      expect(
        content.contains('<string>Heart Rate Dashboard</string>'),
        isTrue,
        reason: 'CFBundleDisplayName should be set to "Heart Rate Dashboard"',
      );
    });

    test('Info.plist contains correct CFBundleName', () {
      final infoPlistFile = File('ios/Runner/Info.plist');
      expect(
        infoPlistFile.existsSync(),
        isTrue,
        reason: 'Info.plist file should exist',
      );

      final content = infoPlistFile.readAsStringSync();

      // Verify CFBundleName is set to heart_rate_dashboard
      expect(
        content.contains('<key>CFBundleName</key>'),
        isTrue,
        reason: 'Info.plist should contain CFBundleName key',
      );
      expect(
        content.contains('<string>heart_rate_dashboard</string>'),
        isTrue,
        reason: 'CFBundleName should be set to "heart_rate_dashboard"',
      );
    });

    test('project.pbxproj contains correct bundle identifier for Runner', () {
      final projectFile = File('ios/Runner.xcodeproj/project.pbxproj');
      expect(
        projectFile.existsSync(),
        isTrue,
        reason: 'project.pbxproj file should exist',
      );

      final content = projectFile.readAsStringSync();

      // Verify PRODUCT_BUNDLE_IDENTIFIER for Runner target
      expect(
        content.contains(
          'PRODUCT_BUNDLE_IDENTIFIER = org.dhuyvetter.heart_rate_dashboard;',
        ),
        isTrue,
        reason:
            'Bundle identifier should be org.dhuyvetter.heart_rate_dashboard',
      );

      // Verify PRODUCT_BUNDLE_IDENTIFIER for RunnerTests target
      expect(
        content.contains(
          'PRODUCT_BUNDLE_IDENTIFIER = org.dhuyvetter.heart_rate_dashboard.RunnerTests;',
        ),
        isTrue,
        reason:
            'RunnerTests bundle identifier should be org.dhuyvetter.heart_rate_dashboard.RunnerTests',
      );
    });

    test('iOS icon assets are installed', () {
      final appIconDir = Directory(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset',
      );
      expect(
        appIconDir.existsSync(),
        isTrue,
        reason: 'AppIcon.appiconset directory should exist',
      );

      // Verify key icon files exist
      final requiredIcons = [
        'Icon-App-1024x1024@1x.png',
        'Icon-App-60x60@2x.png',
        'Icon-App-60x60@3x.png',
        'Icon-App-76x76@1x.png',
        'Icon-App-76x76@2x.png',
        'Contents.json',
      ];

      for (final iconName in requiredIcons) {
        final iconFile = File('${appIconDir.path}/$iconName');
        expect(
          iconFile.existsSync(),
          isTrue,
          reason: 'Icon file $iconName should exist',
        );
      }
    });
  });
}
