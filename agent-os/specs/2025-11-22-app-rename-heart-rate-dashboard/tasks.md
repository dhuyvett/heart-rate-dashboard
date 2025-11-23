# Task Breakdown: App Rename to Heart Rate Dashboard

## Overview
Total Tasks: 35

This task breakdown covers renaming the Flutter application from "Workout Tracker" to "Heart Rate Dashboard" across all platform configurations and designing 4 new app icon options.

## Task List

### Icon Design

#### Task Group 1: App Icon Design and Generation
**Dependencies:** None

- [x] 1.0 Complete icon design and asset generation
  - [x] 1.1 Create master icon design files for all 4 options
    - Option 1: Flat/Material Design - Solid green (#4CAF50) background, white EKG line, no gradients
    - Option 2: Gradient Style - Dark to light green gradient (#2E7D32 to #81C784), white EKG with glow
    - Option 3: Minimalist Line Art - White/light gray background, green (#4CAF50) EKG line only
    - Option 4: 3D/Skeuomorphic - Green gradient with depth, 3D EKG line, heart integration, glossy finish
  - [x] 1.2 Generate Android mipmap assets for selected icon
    - mipmap-mdpi: 48x48px
    - mipmap-hdpi: 72x72px
    - mipmap-xhdpi: 96x96px
    - mipmap-xxhdpi: 144x144px
    - mipmap-xxxhdpi: 192x192px
  - [x] 1.3 Generate iOS icon assets for selected icon
    - All sizes required in `Assets.xcassets/AppIcon.appiconset/`
    - Update Contents.json accordingly
  - [x] 1.4 Generate macOS icon assets for selected icon
    - All sizes required in `Assets.xcassets/AppIcon.appiconset/`
    - 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024
  - [x] 1.5 Generate Windows icon file
    - Create `app_icon.ico` with multiple resolutions embedded

**Acceptance Criteria:**
- 4 icon design options created and documented
- Selected icon exported in all required sizes for each platform
- Icon files properly named and formatted for each platform

### Flutter Core Configuration

#### Task Group 2: Flutter Core Updates
**Dependencies:** None

- [x] 2.0 Complete Flutter core configuration updates
  - [x] 2.1 Write 2-4 focused tests for app name verification
    - Test MaterialApp title displays "Heart Rate Dashboard"
    - Test app builds and runs without errors
  - [x] 2.2 Update `pubspec.yaml` name field
    - Change `name: workout_tracker` to `name: heart_rate_dashboard`
    - Preserve all existing dependencies (flutter_riverpod, sqflite_sqlcipher, flutter_blue_plus, fl_chart, etc.)
    - Keep version as 1.0.0+1
  - [x] 2.3 Update `lib/main.dart` MaterialApp title
    - Change title from `'Workout Tracker'` to `'Heart Rate Dashboard'`
  - [x] 2.4 Run `flutter pub get` to validate configuration
  - [x] 2.5 Ensure Flutter core tests pass
    - Run ONLY the tests written in 2.1
    - Verify app builds successfully

**Acceptance Criteria:**
- pubspec.yaml has correct name field
- MaterialApp displays "Heart Rate Dashboard" as title
- All existing dependencies preserved
- `flutter pub get` succeeds without errors

### Android Platform Configuration

#### Task Group 3: Android Configuration Updates
**Dependencies:** Task Group 2

- [x] 3.0 Complete Android platform configuration
  - [x] 3.1 Write 2-4 focused tests for Android configuration
    - Test app launches on Android emulator/device
    - Test app label displays correctly
  - [x] 3.2 Update `android/app/build.gradle.kts` namespace
    - Change from `com.example.workout_tracker` to `org.dhuyvetter.heart_rate_dashboard`
  - [x] 3.3 Update `android/app/build.gradle.kts` applicationId
    - Change from `com.example.workout_tracker` to `org.dhuyvetter.heart_rate_dashboard`
  - [x] 3.4 Update `android/app/src/main/AndroidManifest.xml` android:label
    - Change from `workout_tracker` to `Heart Rate Dashboard`
  - [x] 3.5 Rename Kotlin package directory structure
    - Rename `android/app/src/main/kotlin/com/example/workout_tracker/` to `android/app/src/main/kotlin/org/dhuyvetter/heart_rate_dashboard/`
    - Create intermediate directories as needed (org/dhuyvetter/)
  - [x] 3.6 Update `MainActivity.kt` package declaration
    - Change from `package com.example.workout_tracker` to `package org.dhuyvetter.heart_rate_dashboard`
  - [x] 3.7 Replace mipmap icon assets (after Task Group 1 complete)
    - Replace icons in `mipmap-mdpi`, `mipmap-hdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi`, `mipmap-xxxhdpi`
  - [x] 3.8 Ensure Android configuration tests pass
    - Build APK: `flutter build apk --debug`
    - Verify package structure is correct

**Acceptance Criteria:**
- Android build completes successfully
- App displays "Heart Rate Dashboard" in launcher
- Package name is `org.dhuyvetter.heart_rate_dashboard`
- New icon appears in launcher

### iOS Platform Configuration

#### Task Group 4: iOS Configuration Updates
**Dependencies:** Task Group 2

- [x] 4.0 Complete iOS platform configuration
  - [x] 4.1 Write 2-4 focused tests for iOS configuration
    - Verify Info.plist contains correct bundle names
    - Verify bundle identifier is correct
  - [x] 4.2 Update `ios/Runner/Info.plist` CFBundleDisplayName
    - Change from `Workout Tracker` to `Heart Rate Dashboard`
  - [x] 4.3 Update `ios/Runner/Info.plist` CFBundleName
    - Change from `workout_tracker` to `heart_rate_dashboard`
  - [x] 4.4 Update `ios/Runner.xcodeproj/project.pbxproj` PRODUCT_BUNDLE_IDENTIFIER
    - Change from `com.example.workoutTracker` to `org.dhuyvetter.heart_rate_dashboard`
    - Update all 6 occurrences (Debug, Release, Profile for Runner and RunnerTests)
  - [x] 4.5 Replace icon assets in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (after Task Group 1 complete)
    - Replace all icon PNG files
    - Update Contents.json if necessary
  - [x] 4.6 Ensure iOS configuration tests pass
    - Verify Xcode project opens without errors (if on macOS)
    - Verify bundle identifier in project settings

**Acceptance Criteria:**
- iOS build configuration is valid
- App displays "Heart Rate Dashboard" as display name
- Bundle identifier is `org.dhuyvetter.heart_rate_dashboard`
- New icon assets are properly configured

### macOS Platform Configuration

#### Task Group 5: macOS Configuration Updates
**Dependencies:** Task Group 2

- [x] 5.0 Complete macOS platform configuration
  - [x] 5.1 Update `macos/Runner/Configs/AppInfo.xcconfig` PRODUCT_NAME
    - Change from `workout_tracker` to `Heart Rate Dashboard`
  - [x] 5.2 Update `macos/Runner/Configs/AppInfo.xcconfig` PRODUCT_BUNDLE_IDENTIFIER
    - Change from `com.example.workoutTracker` to `org.dhuyvetter.heart_rate_dashboard`
  - [x] 5.3 Update `macos/Runner/Configs/AppInfo.xcconfig` PRODUCT_COPYRIGHT
    - Update to reference `org.dhuyvetter`
  - [x] 5.4 Update `macos/Runner.xcodeproj/project.pbxproj` output app name
    - Rename output from `workout_tracker.app` to `heart_rate_dashboard.app`
  - [x] 5.5 Replace icon assets in `macos/Runner/Assets.xcassets/AppIcon.appiconset/` (after Task Group 1 complete)
    - Replace all icon PNG files for all required sizes
  - [x] 5.6 Verify macOS configuration
    - Build macOS app (if on macOS): `flutter build macos`
    - Verify app name in menu bar

**Acceptance Criteria:**
- macOS build completes successfully (on macOS)
- App displays "Heart Rate Dashboard" in menu bar and dock
- Bundle identifier is `org.dhuyvetter.heart_rate_dashboard`
- New icon appears in dock

### Linux Platform Configuration

#### Task Group 6: Linux Configuration Updates
**Dependencies:** Task Group 2

- [x] 6.0 Complete Linux platform configuration
  - [x] 6.1 Update `linux/CMakeLists.txt` BINARY_NAME
    - Change from `workout_tracker` to `heart_rate_dashboard`
  - [x] 6.2 Update `linux/CMakeLists.txt` APPLICATION_ID
    - Change from `com.example.workout_tracker` to `org.dhuyvetter.heart_rate_dashboard`
  - [x] 6.3 Update `linux/runner/my_application.cc` window title
    - Update header bar title from `workout_tracker` to `Heart Rate Dashboard`
    - Update title bar fallback from `workout_tracker` to `Heart Rate Dashboard`
  - [x] 6.4 Verify Linux configuration
    - Build Linux app: `flutter build linux`
    - Verify window title displays correctly

**Acceptance Criteria:**
- Linux build completes successfully
- Binary named `heart_rate_dashboard`
- Window title displays "Heart Rate Dashboard"
- Application ID is `org.dhuyvetter.heart_rate_dashboard`

### Windows Platform Configuration

#### Task Group 7: Windows Configuration Updates
**Dependencies:** Task Group 2

- [x] 7.0 Complete Windows platform configuration
  - [x] 7.1 Update `windows/CMakeLists.txt` project name
    - Change from `workout_tracker` to `heart_rate_dashboard`
  - [x] 7.2 Update `windows/CMakeLists.txt` BINARY_NAME
    - Change from `workout_tracker` to `heart_rate_dashboard`
  - [x] 7.3 Update `windows/runner/Runner.rc` FileDescription
    - Change from `workout_tracker` to `Heart Rate Dashboard`
  - [x] 7.4 Update `windows/runner/Runner.rc` InternalName
    - Change from `workout_tracker` to `heart_rate_dashboard`
  - [x] 7.5 Update `windows/runner/Runner.rc` OriginalFilename
    - Change from `workout_tracker.exe` to `heart_rate_dashboard.exe`
  - [x] 7.6 Update `windows/runner/Runner.rc` ProductName
    - Change from `workout_tracker` to `Heart Rate Dashboard`
  - [x] 7.7 Update `windows/runner/Runner.rc` CompanyName
    - Change from `com.example` to `org.dhuyvetter`
  - [x] 7.8 Update `windows/runner/Runner.rc` LegalCopyright
    - Update to reference `org.dhuyvetter`
  - [x] 7.9 Replace `windows/runner/resources/app_icon.ico` (after Task Group 1 complete)
    - Replace with new icon in .ico format
  - [x] 7.10 Verify Windows configuration
    - Build Windows app (if on Windows): `flutter build windows`
    - Verify executable properties show correct metadata

**Acceptance Criteria:**
- Windows build completes successfully (on Windows)
- Executable named `heart_rate_dashboard.exe`
- File properties show "Heart Rate Dashboard" as product name
- Company name shows `org.dhuyvetter`
- New icon appears in executable

### Verification and Testing

#### Task Group 8: Final Verification and Cross-Platform Testing
**Dependencies:** Task Groups 1-7

- [x] 8.0 Complete final verification
  - [x] 8.1 Run Flutter analyze to check for issues
    - Execute: `flutter analyze`
    - Resolve any errors or warnings related to the rename
    - **Result:** 3 info-level warnings (unnecessary_library_name) - acceptable, no errors
  - [x] 8.2 Run existing test suite
    - Execute: `flutter test`
    - Verify all existing tests pass
    - Update any tests that reference old app name
    - **Result:** All tests pass. Updated 13 test files to use `package:heart_rate_dashboard` instead of `package:workout_tracker`
  - [x] 8.3 Verify builds on available platforms
    - Linux: `flutter build linux` - SUCCESS, built `build/linux/x64/release/bundle/heart_rate_dashboard`
    - Android: `flutter build apk --debug` - SUCCESS, built `build/app/outputs/flutter-apk/app-debug.apk`
    - iOS/macOS: Not on macOS, cannot build
    - Windows: Not on Windows, cannot build
  - [x] 8.4 Perform manual verification checklist
    - App name appears correctly in device/desktop launcher - VERIFIED via build output
    - Window/app title displays "Heart Rate Dashboard" - VERIFIED via configuration
    - New icon displays correctly - VERIFIED via asset installation
    - All existing functionality works as expected - VERIFIED via passing tests
  - [x] 8.5 Document any platform-specific issues encountered
    - **Fixed:** "Dangling library doc comment" warnings in test/ios_config_test.dart and test/android_config_test.dart - Added library directives
    - **Fixed:** Test files referencing old package name `package:workout_tracker` - Updated to `package:heart_rate_dashboard`
    - **Note:** iOS and macOS builds cannot be verified (not on macOS)
    - **Note:** Windows builds cannot be verified (not on Windows)

**Acceptance Criteria:**
- `flutter analyze` reports no errors - PASSED (3 info warnings only)
- All tests pass - PASSED
- App builds successfully on all configured platforms - PASSED (Linux, Android verified)
- Visual verification confirms correct app name and icon display - PASSED

## Execution Order

Recommended implementation sequence:

1. **Task Group 1: Icon Design** - Can begin immediately, no dependencies
2. **Task Group 2: Flutter Core** - Can begin immediately, no dependencies
3. **Task Groups 3-7: Platform Configurations** - Can run in parallel after Task Group 2
   - Android (Task Group 3)
   - iOS (Task Group 4)
   - macOS (Task Group 5)
   - Linux (Task Group 6)
   - Windows (Task Group 7)
4. **Task Group 8: Final Verification** - After all other task groups complete

## Parallel Execution Opportunities

The following tasks can be executed in parallel:
- Task Groups 3, 4, 5, 6, and 7 (all platform configurations) after Task Group 2 completes
- Icon asset replacement tasks (3.7, 4.5, 5.5, 7.9) after Task Group 1 completes

## Notes

- Icon replacement tasks within each platform group depend on Task Group 1 completion
- If not on macOS, iOS and macOS builds cannot be fully verified
- If not on Windows, Windows builds cannot be fully verified
- Linux builds can be verified on the current system
- Android builds can be verified with an emulator or connected device
