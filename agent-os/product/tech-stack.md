# Tech Stack

## Framework & Runtime
- **Application Framework:** Flutter SDK ^3.10.0
- **Language:** Dart (version bundled with Flutter SDK)
- **Package Manager:** pub (Flutter's package manager)
- **Platform Support:** Android, iOS, Web, Linux, macOS, Windows (cross-platform)

## Frontend & UI
- **UI Framework:** Flutter Material Design
- **Icons:** Cupertino Icons (included for iOS-style icons)
- **Charts & Visualization:** fl_chart (privacy-friendly, no analytics, pure Dart/Flutter implementation)
- **Design System:** Material Design 3 components with custom theming for simplicity

## State Management
- **Primary State Management:** Riverpod (recommended for privacy-first architecture)
  - Type-safe, compile-time dependency injection
  - No runtime reflection or code generation overhead
  - Easy to test without complex mocking
  - Excellent for managing device connections and data streams
- **Alternative:** Provider (simpler option if Riverpod proves too complex)

## Database & Storage
- **Local Database:** Sqflite (SQLite for Flutter)
  - Encrypted database support via sqlcipher_flutter_libs
  - No network capability, purely local storage
  - Mature, well-tested, and widely used
  - SQL provides flexibility for complex queries on workout data
- **Key-Value Storage:** shared_preferences (for app settings and preferences)
- **Secure Storage:** flutter_secure_storage (for sensitive data like device pairing keys)

## Device Integration
- **Bluetooth Low Energy:** flutter_blue_plus
  - Active development and maintenance
  - Supports all major platforms
  - Heart rate monitor profile (HRM) support
  - No analytics or tracking dependencies
- **GPS & Location:** geolocator
  - Minimal permissions model
  - Works offline (no network location services)
  - Efficient battery usage
  - Platform-agnostic API

## Mapping (Future GPS Feature)
- **Map Display:** flutter_map with offline tile caching
  - Open-source, privacy-friendly
  - Supports offline map tiles (no required network calls)
  - Can use OpenStreetMap data downloaded locally
  - Alternative: Google Maps (if user preference, but less privacy-aligned)

## Data Export & File Handling
- **CSV Generation:** csv package (pure Dart, no dependencies)
- **File System Access:** path_provider (for app directories)
- **File Picker:** file_picker (for user-selected save locations)
- **File I/O:** dart:io (built-in, no external dependency)

## Testing & Quality
- **Test Framework:** Flutter Test (built-in framework)
- **Widget Testing:** flutter_test package (included with Flutter)
- **Integration Testing:** integration_test package (official Flutter package)
- **Linting/Formatting:** flutter_lints ^6.0.0 (official recommended lints)
- **Code Formatter:** dart format (built-in)

## Development & Build Tools
- **IDE Support:** Android Studio, VS Code with Flutter extensions
- **Hot Reload:** Flutter's built-in hot reload for rapid development
- **Debug Tools:** Flutter DevTools for performance profiling
- **Build System:** Flutter build system (no additional tools required)

## Deployment & Distribution
- **Android:** APK and App Bundle builds via flutter build
- **iOS:** App Store builds via flutter build (requires macOS)
- **Desktop:** Direct executables for Linux, Windows, macOS
- **Distribution:** Direct downloads, F-Droid (for Android open-source), platform app stores

## Explicitly Excluded Services
- **NO Cloud Storage:** No Firebase, AWS, Azure, or any cloud storage
- **NO Analytics:** No Google Analytics, Firebase Analytics, Mixpanel, or any tracking
- **NO Crash Reporting:** No Sentry, Crashlytics, or error reporting services
- **NO Authentication Services:** No Auth0, Firebase Auth, or account systems
- **NO Social APIs:** No sharing, social login, or third-party integrations
- **NO Advertising SDKs:** No ad networks or monetization frameworks
- **NO Push Notifications:** No FCM, APNs services, or notification backends
- **NO Backend Services:** No API servers, databases, or cloud functions

## Privacy & Security Principles
- **Minimal Dependencies:** Only essential packages; each dependency reviewed for privacy
- **No Network Permissions:** App requests no internet permission on Android
- **Local-First Architecture:** All data processing and storage happens on device
- **Encryption:** Local database encrypted at rest
- **No Telemetry:** Zero data collection, no usage statistics, no diagnostics transmission
- **Open Source Preferred:** Prioritize open-source dependencies for transparency
- **Permission Minimization:** Request only Bluetooth and Location (when GPS feature active)

## Development Workflow
- **Version Control:** Git with clear commit messages and feature branches
- **CI/CD:** GitHub Actions for automated testing (build and test only, no deployment)
- **Code Review:** Pull request reviews before merging to main branch
- **Testing Requirements:** Unit tests for business logic, widget tests for UI components
- **Documentation:** Inline code documentation and architectural decision records
