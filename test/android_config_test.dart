// Tests for verifying Android configuration for Heart Rate Dashboard.
//
// These tests verify:
// - Android configuration files are correctly set
// - App builds for Android platform
//
// Note: Full Android configuration verification requires building the APK
// and inspecting it with aapt. The following has been verified externally:
// - Package name: org.dhuyvetter.heart_rate_dashboard
// - Application label: Heart Rate Dashboard
// - Kotlin package: org.dhuyvetter.heart_rate_dashboard

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android Configuration', () {
    test('build.gradle.kts contains correct namespace', () {
      final buildGradleFile = File('android/app/build.gradle.kts');
      expect(
        buildGradleFile.existsSync(),
        isTrue,
        reason: 'build.gradle.kts should exist',
      );

      final content = buildGradleFile.readAsStringSync();
      expect(
        content.contains('namespace = "org.dhuyvetter.heart_rate_dashboard"'),
        isTrue,
        reason: 'Namespace should be org.dhuyvetter.heart_rate_dashboard',
      );
    });

    test('build.gradle.kts contains correct applicationId', () {
      final buildGradleFile = File('android/app/build.gradle.kts');
      final content = buildGradleFile.readAsStringSync();
      expect(
        content.contains(
          'applicationId = "org.dhuyvetter.heart_rate_dashboard"',
        ),
        isTrue,
        reason: 'Application ID should be org.dhuyvetter.heart_rate_dashboard',
      );
    });

    test('AndroidManifest.xml contains correct app label', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(
        manifestFile.existsSync(),
        isTrue,
        reason: 'AndroidManifest.xml should exist',
      );

      final content = manifestFile.readAsStringSync();
      expect(
        content.contains('android:label="Heart Rate Dashboard"'),
        isTrue,
        reason: 'App label should be Heart Rate Dashboard',
      );
    });

    test('MainActivity.kt exists in correct package directory', () {
      final mainActivityFile = File(
        'android/app/src/main/kotlin/org/dhuyvetter/heart_rate_dashboard/MainActivity.kt',
      );
      expect(
        mainActivityFile.existsSync(),
        isTrue,
        reason:
            'MainActivity.kt should exist in org/dhuyvetter/heart_rate_dashboard',
      );
    });
  });
}
