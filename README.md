# Heart Rate Dashboard

[![Build](https://github.com/dhuyvett/heart-rate-dashboard/actions/workflows/build.yml/badge.svg)](https://github.com/dhuyvett/heart-rate-dashboard/actions/workflows/build.yml)

**Your heart rate data belongs to you.**

Heart Rate Dashboard is a privacy-first heart rate monitoring app that keeps your fitness data where it belongs—on your device. No accounts. No cloud. No tracking.

## Why Privacy Matters

Modern fitness apps harvest your biometric data, location history, and workout patterns—uploading everything to corporate servers, sharing with third parties, and building profiles for targeted advertising. You lose control the moment your data leaves your device.

**Heart Rate Dashboard takes a different approach:**

- **Zero Network Transmission** — The app makes no network requests. Ever. Your data physically cannot leave your device.
- **No Accounts Required** — No email, no login, no personally identifiable information collected.
- **Encrypted Local Storage** — SQLCipher encryption on Android/iOS; desktop uses unencrypted local SQLite.
- **Desktop Encryption Notice** — Desktop builds store data unencrypted; the app shows a reminder on first launch.
- **Minimal Permissions** — Bluetooth access for heart rate monitors; optional location only when tracking speed/distance.
- **No Analytics or Telemetry** — No usage tracking, no crash reporting services, no advertising SDKs.

## What It Does

Connect to any standard Bluetooth heart rate monitor and see your heart rate displayed in real-time with color-coded training zones. Track your workout sessions with automatic recording, view statistics, and maintain complete control over your data.

**Key Features:**
- Real-time BPM display with heart rate zone visualization
- Session statistics (duration, average/min/max heart rate)
- Session history and detail views
- Demo mode for testing without hardware
- Optional GPS speed and distance tracking (mobile)
- CSV export (planned)
- Works completely offline

## Getting Started

1. Install on your Android or iOS device
2. Grant Bluetooth permissions when prompted
3. Scan for devices and connect your heart rate monitor (or try Demo Mode)
4. Start your workout

## Documentation

| Document                                                         | Description                                                   |
| ---------------------------------------------------------------- | ------------------------------------------------------------- |
| [CONTRIBUTING.md](CONTRIBUTING.md)                               | Development setup, prerequisites, and contribution guidelines |
| [agent-os/product/mission.md](agent-os/product/mission.md)       | Product vision, target users, and strategy                    |
| [agent-os/product/roadmap.md](agent-os/product/roadmap.md)       | Planned features and development priorities                   |
| [agent-os/product/tech-stack.md](agent-os/product/tech-stack.md) | Technical architecture and design decisions                   |

## Platform Support

| Platform                      | Status           |
| ----------------------------- | ---------------- |
| Android                       | Full BLE support |
| iOS                           | Full BLE support |
| Desktop (Linux/macOS/Windows) | Full BLE support |

## License

See LICENSE file for details.
