# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application called Heart Rate Dashboard - a privacy-first heart rate monitoring application for tracking heart rate during workouts.

## Development Commands

### Running the Application
```bash
flutter run                    # Run on connected device/emulator
flutter run -d chrome          # Run on Chrome (web)
flutter run -d linux          # Run on Linux desktop
flutter run -d windows        # Run on Windows desktop
flutter run -d macos          # Run on macOS desktop
```

### Testing
```bash
flutter test                   # Run all tests
flutter test test/widget_test.dart  # Run specific test file
flutter test --coverage        # Run tests with coverage
```

### Code Quality
```bash
flutter analyze                # Run static analysis
flutter pub outdated          # Check for outdated dependencies
```

### Building
```bash
flutter build apk             # Build Android APK
flutter build appbundle       # Build Android App Bundle
flutter build ios             # Build iOS app (requires macOS)
flutter build web             # Build web app
flutter build linux           # Build Linux desktop app
flutter build windows         # Build Windows desktop app
flutter build macos           # Build macOS desktop app
```

### Dependencies
```bash
flutter pub get               # Install dependencies
flutter pub upgrade           # Upgrade dependencies
```

### Hot Reload
When the app is running, press `r` in the terminal to hot reload or `R` to hot restart.

## Project Structure

- **lib/**: Main application source code
  - `main.dart`: Application entry point, contains the main widget tree
- **test/**: Widget and unit tests
- **android/**: Android-specific native code and configuration
- **ios/**: iOS-specific native code and configuration
- **linux/**: Linux desktop-specific configuration
- **macos/**: macOS desktop-specific configuration
- **windows/**: Windows desktop-specific configuration
- **web/**: Web-specific configuration
- **pubspec.yaml**: Project dependencies and Flutter configuration
- **analysis_options.yaml**: Dart analyzer configuration using `flutter_lints`

## Architecture Notes

This is a standard Flutter project using:
- **Flutter SDK**: ^3.10.0
- **Linting**: flutter_lints ^6.0.0 (recommended lints enabled)
- **Platform Support**: Android, iOS, Web, Linux, macOS, Windows

The application provides:
- Real-time heart rate monitoring via Bluetooth Low Energy (BLE)
- Heart rate zone visualization using Hopkins Medicine methodology
- Local-only encrypted data storage with SQLCipher
- Demo mode for testing without physical hardware

## Development Notes

- The project uses Material Design with `uses-material-design: true`
- Cupertino Icons are included for iOS-style icons
- Hot reload is available for rapid iteration during development
- The analysis options include recommended Flutter lints for code quality
