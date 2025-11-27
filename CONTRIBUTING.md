# Contributing to Heart Rate Dashboard

Thank you for your interest in contributing to Heart Rate Dashboard! This document provides guidelines and instructions for working with this project.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.10.0 or higher)
  - Install from [flutter.dev](https://flutter.dev/docs/get-started/install)
  - Run `flutter doctor` to verify installation
- **Git** for version control
- **IDE/Editor** (recommended):
  - Android Studio / IntelliJ IDEA with Flutter plugin
  - VS Code with Flutter and Dart extensions

### Platform-Specific Dependencies

#### Linux

For running tests and building the Linux desktop app:

```bash
sudo apt-get update
sudo apt-get install -y \
  clang \
  cmake \
  lld \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  libsqlite3-dev \
  libsecret-1-dev
```

| Package | Purpose |
|---------|---------|
| `clang` | C/C++ compiler for native code |
| `cmake` | Build system generator |
| `lld` | LLVM linker (required for running tests with native FFI) |
| `ninja-build` | Fast build system |
| `pkg-config` | Library configuration tool |
| `libgtk-3-dev` | GTK3 development files for desktop UI |
| `libsqlite3-dev` | SQLite development files for database |
| `libsecret-1-dev` | Secret Service library for secure key storage |

#### macOS

For building the iOS and macOS apps:

- **Xcode** (from App Store)
- **CocoaPods**: `sudo gem install cocoapods`

#### Windows

For building the Windows desktop app:

- **Visual Studio 2022** with "Desktop development with C++" workload

#### Android

For building Android apps:

- **Java Development Kit (JDK) 17**
  - Linux: `sudo apt-get install openjdk-17-jdk`
  - macOS: `brew install openjdk@17`
  - Windows: Download from [Adoptium](https://adoptium.net/)
- **Android SDK** (installed via Android Studio or Flutter)

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd heart_rate_dashboard
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify your setup**
   ```bash
   flutter doctor
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

   Or select a specific device:
   ```bash
   flutter devices              # List available devices
   flutter run -d <device-id>   # Run on specific device
   ```

5. **Set up pre-commit hooks** (recommended)

   Pre-commit hooks automatically check your code before each commit to ensure quality and prevent secrets from being committed.

   ```bash
   # Install pre-commit (requires Python)
   pip install pre-commit

   # Install the git hooks
   pre-commit install

   # (Optional) Run against all files to test
   pre-commit run --all-files
   ```

   The pre-commit hooks will automatically:
   - Format your Dart code with `dart format`
   - Run static analysis with `flutter analyze`
   - Check for secrets and sensitive information with gitleaks
   - Validate YAML files
   - Remove trailing whitespace
   - Ensure consistent line endings
   - Run tests before pushing (on `git push`)

   **Note**: If you don't have Python/pip installed:
   - **macOS**: `brew install python`
   - **Linux**: `sudo apt-get install python3-pip` (Debian/Ubuntu) or equivalent
   - **Windows**: Download from [python.org](https://www.python.org/downloads/)

## Development Workflow

### Running the Application

- **Hot Reload**: Press `r` in the terminal while the app is running to see your changes instantly
- **Hot Restart**: Press `R` to fully restart the app
- **Web**: `flutter run -d chrome`
- **Desktop**: `flutter run -d linux` (or `windows`, `macos`)

### Code Quality

If you've set up pre-commit hooks, these checks run automatically before each commit. Otherwise, manually ensure your code passes all quality checks:

```bash
# Run static analysis
flutter analyze

# Format your code
dart format .

# Run tests
flutter test
```

### Testing

- **Run all tests**: `flutter test`
- **Run specific test**: `flutter test test/widget_test.dart`
- **Run with coverage**: `flutter test --coverage`

### Building

```bash
# Android
flutter build apk              # Debug APK
flutter build appbundle        # Release bundle for Play Store

# iOS (requires macOS)
flutter build ios

# Web
flutter build web

# Desktop
flutter build linux            # or windows, macos
```

## Code Style Guidelines

This project follows the official Dart style guide and uses `flutter_lints` for code analysis.

### General Rules

- Use **2 spaces** for indentation (enforced by .editorconfig)
- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Keep lines under 80 characters where reasonable
- Use meaningful variable and function names
- Add comments for complex logic

### Widget Organization

```dart
class MyWidget extends StatelessWidget {
  // 1. Constructor
  const MyWidget({super.key, required this.title});

  // 2. Fields
  final String title;

  // 3. Build method
  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

### File Organization

- One widget per file for complex widgets
- Group related widgets in the same directory
- Use descriptive file names in snake_case (e.g., `workout_list_page.dart`)

## Project Structure

```
lib/
├── main.dart           # App entry point
├── models/            # Data models
├── screens/           # UI screens/pages
├── widgets/           # Reusable widgets
├── services/          # Business logic and API calls
└── utils/             # Helper functions and constants

test/
├── widget_test.dart   # Widget tests
├── unit/             # Unit tests
└── integration/      # Integration tests
```

## Commit Guidelines

### Commit Message Format

Use clear, descriptive commit messages:

```
type: Brief description (50 chars or less)

More detailed explanation if needed (wrap at 72 characters).
Include motivation for the change and contrast with previous behavior.

- Bullet points are okay
- Use imperative mood: "Add feature" not "Added feature"
```

### Commit Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat: Add workout history screen

fix: Resolve timer not stopping on workout completion

docs: Update README with new setup instructions

test: Add unit tests for workout model
```

## Pull Request Process

1. Create a new branch for your feature/fix:
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. Make your changes and commit them following the commit guidelines

3. Ensure all tests pass and code is formatted:
   ```bash
   flutter analyze
   dart format .
   flutter test
   ```

4. Push your branch and create a pull request

5. Wait for review and address any feedback

## Common Tasks

### Adding a New Dependency

1. Add the dependency to `pubspec.yaml`:
   ```yaml
   dependencies:
     package_name: ^version
   ```

2. Run `flutter pub get`

3. Import and use in your code:
   ```dart
   import 'package:package_name/package_name.dart';
   ```

### Creating a New Screen

1. Create a new file in `lib/screens/`:
   ```dart
   // lib/screens/my_screen.dart
   import 'package:flutter/material.dart';

   class MyScreen extends StatelessWidget {
     const MyScreen({super.key});

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: const Text('My Screen')),
         body: const Center(child: Text('Content')),
       );
     }
   }
   ```

2. Add navigation in the parent widget:
   ```dart
   Navigator.push(
     context,
     MaterialPageRoute(builder: (context) => const MyScreen()),
   );
   ```

### Debugging

- Use the `AppLogger` utility for structured logging (preferred):
  ```dart
  import 'package:heart_rate_dashboard/utils/app_logger.dart';

  final _logger = AppLogger.getLogger('MyClass');
  _logger.d('Debug message');
  _logger.i('Info message');
  _logger.w('Warning message');
  _logger.e('Error message', error: e, stackTrace: stackTrace);
  ```
- Use Flutter DevTools for advanced debugging:
  ```bash
  flutter run
  # Then press 'v' in the terminal to open DevTools
  ```
- Use breakpoints in your IDE

### Platform-Specific Notes

#### Linux Secure Storage

The app uses `flutter_secure_storage` for device-specific encryption keys on Linux. This requires `libsecret-1-dev` to be installed (see Platform-Specific Dependencies above).

**Note**: If you encounter the error `The following required packages were not found: libsecret-1>=0.18.4`, install the missing dependency:
```bash
sudo apt-get install libsecret-1-dev
```

#### Desktop Database Encryption

- **Mobile (Android/iOS)**: Uses SQLCipher with device-specific keys stored in Android Keystore/iOS Keychain
- **Desktop (Linux/macOS/Windows)**: Uses unencrypted SQLite due to lack of SQLCipher FFI support
- Keys are managed by `SecureKeyManager` utility in `lib/utils/secure_key_manager.dart`

## Getting Help

- Check the [Flutter documentation](https://flutter.dev/docs)
- Review existing code and tests for examples
- Open an issue for bugs or feature requests

## License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.
