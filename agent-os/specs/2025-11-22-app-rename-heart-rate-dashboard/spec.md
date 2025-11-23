# Specification: App Rename to Heart Rate Dashboard

## Goal
Rename the Flutter application from "Workout Tracker" to "Heart Rate Dashboard" across all platform configurations, internal references, and display names, while also designing 4 new app icon options featuring green EKG/pulse line imagery.

## User Stories
- As a user, I want the app to display "Heart Rate Dashboard" as its name so that it accurately reflects the app's primary purpose
- As a developer, I want consistent naming across all platform configurations so that the app identity is unified

## Specific Requirements

**Flutter Core Configuration**
- Update `pubspec.yaml` name field from `workout_tracker` to `heart_rate_dashboard`
- Update `lib/main.dart` MaterialApp title from `'Workout Tracker'` to `'Heart Rate Dashboard'`
- Preserve all existing dependencies, assets, and Flutter configuration settings

**Android Platform Configuration**
- Update `android/app/build.gradle.kts` namespace from `com.example.workout_tracker` to `org.dhuyvetter.heart_rate_dashboard`
- Update `android/app/build.gradle.kts` applicationId from `com.example.workout_tracker` to `org.dhuyvetter.heart_rate_dashboard`
- Update `android/app/src/main/AndroidManifest.xml` android:label from `workout_tracker` to `Heart Rate Dashboard`
- Rename Kotlin package directory from `com/example/workout_tracker` to `org/dhuyvetter/heart_rate_dashboard`
- Update `MainActivity.kt` package declaration to `org.dhuyvetter.heart_rate_dashboard`
- Replace all mipmap icon assets in `android/app/src/main/res/mipmap-*` directories with new icon

**iOS Platform Configuration**
- Update `ios/Runner/Info.plist` CFBundleDisplayName from `Workout Tracker` to `Heart Rate Dashboard`
- Update `ios/Runner/Info.plist` CFBundleName from `workout_tracker` to `heart_rate_dashboard`
- Update `ios/Runner.xcodeproj/project.pbxproj` PRODUCT_BUNDLE_IDENTIFIER from `com.example.workoutTracker` to `org.dhuyvetter.heart_rate_dashboard` (in all 6 occurrences: Debug, Release, Profile for Runner and RunnerTests)
- Replace all icon assets in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` with new icon

**macOS Platform Configuration**
- Update `macos/Runner/Configs/AppInfo.xcconfig` PRODUCT_NAME from `workout_tracker` to `Heart Rate Dashboard`
- Update `macos/Runner/Configs/AppInfo.xcconfig` PRODUCT_BUNDLE_IDENTIFIER from `com.example.workoutTracker` to `org.dhuyvetter.heart_rate_dashboard`
- Update `macos/Runner/Configs/AppInfo.xcconfig` PRODUCT_COPYRIGHT to reference `org.dhuyvetter`
- Update `macos/Runner.xcodeproj/project.pbxproj` to rename output app from `workout_tracker.app` to `heart_rate_dashboard.app`
- Replace icon assets in `macos/Runner/Assets.xcassets/AppIcon.appiconset/`

**Linux Platform Configuration**
- Update `linux/CMakeLists.txt` BINARY_NAME from `workout_tracker` to `heart_rate_dashboard`
- Update `linux/CMakeLists.txt` APPLICATION_ID from `com.example.workout_tracker` to `org.dhuyvetter.heart_rate_dashboard`
- Update `linux/runner/my_application.cc` window title from `workout_tracker` to `Heart Rate Dashboard` (both header bar and title bar cases)

**Windows Platform Configuration**
- Update `windows/CMakeLists.txt` project name from `workout_tracker` to `heart_rate_dashboard`
- Update `windows/CMakeLists.txt` BINARY_NAME from `workout_tracker` to `heart_rate_dashboard`
- Update `windows/runner/Runner.rc` FileDescription from `workout_tracker` to `Heart Rate Dashboard`
- Update `windows/runner/Runner.rc` InternalName from `workout_tracker` to `heart_rate_dashboard`
- Update `windows/runner/Runner.rc` OriginalFilename from `workout_tracker.exe` to `heart_rate_dashboard.exe`
- Update `windows/runner/Runner.rc` ProductName from `workout_tracker` to `Heart Rate Dashboard`
- Update `windows/runner/Runner.rc` CompanyName from `com.example` to `org.dhuyvetter`
- Update `windows/runner/Runner.rc` LegalCopyright to reference `org.dhuyvetter`
- Replace `windows/runner/resources/app_icon.ico` with new icon

**Icon Design - Option 1: Flat/Material Design**
- Square icon with rounded corners following Material Design guidelines
- Solid green background (hex: #4CAF50 or similar Material Green)
- White simplified EKG/heartbeat line in center
- Clean, minimalist aesthetic with no gradients or shadows
- Line thickness: 3-4px scaled appropriately for each icon size

**Icon Design - Option 2: Gradient Style**
- Square icon with rounded corners
- Gradient background transitioning from dark green (#2E7D32) to light green (#81C784)
- White EKG/pulse line with subtle glow effect
- Modern, vibrant appearance
- Gradient direction: top-left to bottom-right diagonal

**Icon Design - Option 3: Minimalist Line Art**
- Square icon with rounded corners
- Pure white or very light gray background
- Green (#4CAF50) EKG line as the sole visual element
- Ultra-clean, modern aesthetic
- Thin stroke weight (2px at 1024px resolution) for elegant appearance

**Icon Design - Option 4: 3D/Skeuomorphic Style**
- Square icon with rounded corners
- Green gradient background with subtle depth and lighting
- EKG line with 3D effect (shadow, highlight, depth)
- Heart shape subtly integrated with the pulse line
- Glossy finish with light reflection at top

## Existing Code to Leverage

**Current pubspec.yaml structure**
- Existing configuration at `/home/ddhuyvetter/src/workout_tracker/pubspec.yaml` shows standard Flutter project setup
- Preserve all dependencies (flutter_riverpod, sqflite_sqlcipher, flutter_blue_plus, fl_chart, etc.)
- Keep version as 1.0.0+1 unless specifically requested to change

**Android build configuration pattern**
- `android/app/build.gradle.kts` uses Kotlin DSL with namespace and applicationId as separate properties
- Must update both namespace and applicationId consistently
- Kotlin package directory structure must match the new package name exactly

**iOS/macOS Xcode project structure**
- Bundle identifiers in `project.pbxproj` appear in multiple build configurations (Debug, Release, Profile)
- All occurrences must be updated consistently
- `AppInfo.xcconfig` provides centralized configuration for macOS

**Linux CMake configuration**
- `APPLICATION_ID` defined in CMakeLists.txt is used by the application for GTK integration
- Window title set in `my_application.cc` with both header bar and title bar variants

**Windows resource file pattern**
- `Runner.rc` contains version info and metadata displayed in Windows file properties
- All string values in the StringFileInfo block must be updated consistently

## Out of Scope
- Renaming the project directory from `workout_tracker` to `heart_rate_dashboard`
- Changing the internal Dart import paths or package references
- Modifying any application logic or UI functionality
- Updating any test files beyond what is strictly necessary for the rename
- Creating or modifying localization files
- Changing the app version number
- Modifying any signing configurations or certificates
- Creating a splash screen or launch image updates
- Renaming the Runner/RunnerTests target names in Xcode projects
- Updating any CI/CD pipeline configurations
