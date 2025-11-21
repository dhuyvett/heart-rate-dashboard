# Workout Tracker

A privacy-first fitness monitoring application that tracks workouts without compromising personal data.

## Overview

Workout Tracker is an offline-first, local-only workout tracking application designed for privacy-conscious athletes and fitness enthusiasts. Unlike traditional fitness apps that upload data to cloud servers, this application stores all data locally on your device with zero network transmission.

**Core Principles:**
- **Privacy-First Architecture:** All data stored locally with encrypted database
- **Offline-Only Operation:** Full functionality without network connection
- **Simplicity Over Features:** Clean, focused tracking without social features or complexity
- **Zero PII Collection:** No accounts, emails, or personally identifiable information required
- **Minimal Permissions:** Only essential permissions for core functionality

## Features

### Bluetooth Heart Rate Monitoring

Connect to any Bluetooth Low Energy (BLE) heart rate monitor that supports the standard Heart Rate Service (0x180D).

**Real-Time Display:**
- Large, color-coded BPM value readable from a distance
- Heart rate zones calculated using the Hopkins Medicine methodology (220 - age)
- Smooth color transitions as you move between zones
- Real-time scrolling chart showing recent heart rate history

**Heart Rate Zones:**
| Zone | Intensity | % of Max HR | Color |
|------|-----------|-------------|-------|
| Resting | Below target | <50% | Blue |
| Zone 1 | Very Light | 50-60% | Light Blue |
| Zone 2 | Light | 60-70% | Green |
| Zone 3 | Moderate | 70-80% | Yellow |
| Zone 4 | Hard | 80-90% | Orange |
| Zone 5 | Maximum | 90-100% | Red |

**Session Statistics:**
- Duration (HH:MM:SS)
- Average heart rate
- Minimum heart rate
- Maximum heart rate
- All statistics update in real-time

**Automatic Recording:**
- Data recording starts automatically when a device connects
- Heart rate sampled every 1-2 seconds
- All data stored in encrypted local database
- Session ends when device disconnects

**Auto-Reconnection:**
- Automatic reconnection attempts if device unexpectedly disconnects
- Up to 10 retry attempts with exponential backoff
- Visual feedback showing reconnection progress
- Option to retry or select a different device after failures

### Demo Mode

Test the app without a physical heart rate monitor:

- Select "Demo Mode" from the device list
- Simulates realistic heart rate data with natural variability
- All features work identically to a real device connection
- Perfect for app evaluation or screenshots

### Settings

Customize the app to your preferences:

- **Age:** Used to calculate your maximum heart rate and zone boundaries
- **Chart Time Window:** Display 15, 30, 45, or 60 seconds of history
- View calculated zone ranges based on your age
- Settings are saved immediately and persist across app restarts

## Required Permissions

### Android
- **Bluetooth Scan:** Required to discover heart rate monitors
- **Bluetooth Connect:** Required to connect to devices
- **Location (When In Use):** Required by Android OS for BLE scanning (not used for tracking)

### iOS
- **Bluetooth:** Required for all BLE functionality

Note: The app does not use location data for tracking purposes. Location permission on Android is an OS requirement for Bluetooth Low Energy scanning.

## Supported Platforms

| Platform | BLE Support | Status |
|----------|-------------|--------|
| Android | Full | Primary |
| iOS | Full | Primary |
| Linux Desktop | Limited | Demo mode only |
| macOS Desktop | Limited | Demo mode only |
| Windows Desktop | Limited | Demo mode only |
| Web | None | Demo mode only |

## Data Security

- **Encrypted Database:** All workout data stored using SQLCipher encryption
- **No Network Access:** App makes zero network requests
- **Local Storage Only:** Data never leaves your device
- **No Analytics:** No tracking, telemetry, or usage data collection

## Dependencies

The app uses the following key packages:

| Package | Purpose |
|---------|---------|
| flutter_riverpod | State management |
| sqflite_sqlcipher | Encrypted local database |
| flutter_blue_plus | Bluetooth Low Energy communication |
| fl_chart | Real-time heart rate chart visualization |
| shared_preferences | Settings persistence |
| permission_handler | Platform permission management |

## Repository Layout

```
workout_tracker/
├── lib/                          # Application source code
│   ├── main.dart                 # Application entry point
│   ├── models/                   # Data models
│   ├── providers/                # Riverpod state providers
│   ├── screens/                  # UI screens
│   ├── services/                 # BLE, database services
│   ├── utils/                    # Helpers and constants
│   └── widgets/                  # Reusable UI components
├── test/                         # Widget and unit tests
├── agent-os/                     # Development planning and specifications
│   ├── product/                  # Product documentation
│   │   ├── mission.md            # Product vision and strategy
│   │   ├── roadmap.md            # Development roadmap
│   │   └── tech-stack.md         # Technical architecture decisions
│   └── specs/                    # Feature specifications
├── android/                      # Android-specific configuration
├── ios/                          # iOS-specific configuration
├── linux/                        # Linux desktop configuration
├── macos/                        # macOS desktop configuration
├── windows/                      # Windows desktop configuration
├── web/                          # Web-specific configuration
├── pubspec.yaml                  # Flutter dependencies and configuration
├── analysis_options.yaml         # Dart analyzer configuration
└── CLAUDE.md                     # Development guidance for Claude Code
```

## Development

### Prerequisites
- Flutter SDK ^3.10.0
- Dart SDK (included with Flutter)
- Platform-specific development tools (Android Studio, Xcode, etc.)

### Running the Application
```bash
flutter run                    # Run on connected device/emulator
flutter run -d chrome          # Run on Chrome (web) - demo mode only
flutter run -d linux           # Run on Linux desktop - demo mode only
```

### Testing
```bash
flutter test                   # Run all tests
flutter test --coverage        # Run tests with coverage
```

### Code Quality
```bash
flutter analyze                # Run static analysis
```

## Getting Started

1. Install the app on your Android or iOS device
2. Grant Bluetooth permissions when prompted
3. On Android, grant Location permission (required for BLE scanning)
4. Tap "Scan for Devices" to discover nearby heart rate monitors
5. Select your device or choose "Demo Mode" to try the app
6. Watch your heart rate displayed in real-time with color-coded zones
7. Access Settings to configure your age and chart preferences

## Planned Features

- GPS-based speed and distance tracking
- Enhanced analytics and historical visualization
- CSV data export
- Session history browsing

## License

See LICENSE file for details.
