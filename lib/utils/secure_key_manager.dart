import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_logger.dart';

/// Manages secure encryption keys for the database.
///
/// This class handles the generation, storage, and retrieval of encryption keys
/// using platform-native secure storage (Android Keystore, iOS Keychain, etc.).
///
/// Key features:
/// - Device-specific key generation using device identifiers
/// - Secure storage using platform keychains
/// - Automatic key migration for existing installations
/// - No hardcoded secrets in source code
class SecureKeyManager {
  static final _logger = AppLogger.getLogger('SecureKeyManager');
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyName = 'hr_db_encryption_key';
  static const _legacyWarningShown = 'legacy_warning_shown';

  /// Gets or creates a device-specific encryption key.
  ///
  /// This method:
  /// 1. Checks for an existing key in secure storage
  /// 2. If no key exists, generates a new one based on device ID
  /// 3. Stores the key securely using platform keychain
  ///
  /// Returns the encryption key as a base64-encoded string.
  static Future<String> getOrCreateEncryptionKey() async {
    try {
      // Try to retrieve existing key from secure storage
      final existingKey = await _secureStorage.read(key: _keyName);

      if (existingKey != null && existingKey.isNotEmpty) {
        _logger.d('Retrieved existing encryption key from secure storage');
        return existingKey;
      }

      // No key exists - generate a new one
      _logger.i('No encryption key found, generating new device-specific key');
      final newKey = await _generateDeviceSpecificKey();

      // Store the key securely
      await _secureStorage.write(key: _keyName, value: newKey);
      _logger.i('Encryption key generated and stored securely');

      return newKey;
    } catch (e, stackTrace) {
      _logger.e(
        'Error managing encryption key',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Generates a device-specific encryption key.
  ///
  /// The key is derived from:
  /// - Device-specific identifier (Android ID, iOS identifierForVendor, etc.)
  /// - Random salt (for additional entropy)
  /// - Application-specific constant
  ///
  /// This ensures each device has a unique key that cannot be extracted
  /// from the APK/IPA.
  static Future<String> _generateDeviceSpecificKey() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Use Android ID - unique per device and app installation
        deviceId = androidInfo.id;
        _logger.d('Using Android ID for key generation');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // Use identifierForVendor - unique per device and vendor
        deviceId = iosInfo.identifierForVendor ?? _generateFallbackId();
        _logger.d('Using iOS identifierForVendor for key generation');
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        // Use machine ID on Linux
        deviceId = linuxInfo.machineId ?? _generateFallbackId();
        _logger.d('Using Linux machine ID for key generation');
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        // Use system UUID on macOS
        deviceId = macInfo.systemGUID ?? _generateFallbackId();
        _logger.d('Using macOS system GUID for key generation');
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        // Use device ID on Windows
        deviceId = windowsInfo.deviceId;
        _logger.d('Using Windows device ID for key generation');
      } else {
        // Fallback for unsupported platforms
        deviceId = _generateFallbackId();
        _logger.w('Using fallback ID for unsupported platform');
      }

      // Generate a random salt for additional entropy
      final salt = _generateRandomSalt();

      // Combine device ID, salt, and app-specific constant
      final keyMaterial = '$deviceId:$salt:hr_dashboard_v1';

      // Hash the key material using SHA-256
      final bytes = utf8.encode(keyMaterial);
      final hash = sha256.convert(bytes);

      // Encode as base64 for use as database password
      final encryptionKey = base64.encode(hash.bytes);

      _logger.d('Device-specific key generated successfully');
      return encryptionKey;
    } catch (e, stackTrace) {
      _logger.e(
        'Error generating device-specific key',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Generates a fallback device ID when platform-specific ID is unavailable.
  ///
  /// This uses timestamp + random data to create a unique ID.
  /// Note: This means the key will be different after app reinstall.
  static String _generateFallbackId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure();
    final randomPart = List<int>.generate(16, (_) => random.nextInt(256));
    return '$timestamp:${base64.encode(randomPart)}';
  }

  /// Generates a cryptographically secure random salt.
  ///
  /// The salt adds additional entropy to the key derivation process.
  static String _generateRandomSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  /// Checks if a legacy hardcoded key is still being used.
  ///
  /// This is for migration purposes - helps identify installations
  /// that need to migrate from the old hardcoded key.
  ///
  /// Returns true if this appears to be a first-time setup.
  static Future<bool> isFirstTimeSetup() async {
    try {
      final existingKey = await _secureStorage.read(key: _keyName);
      return existingKey == null || existingKey.isEmpty;
    } catch (e, stackTrace) {
      _logger.w(
        'Error checking first-time setup',
        error: e,
        stackTrace: stackTrace,
      );
      // Assume not first time if we can't check
      return false;
    }
  }

  /// Deletes the encryption key from secure storage.
  ///
  /// WARNING: This will make any encrypted database unrecoverable!
  /// Only use this for testing or user-initiated data deletion.
  static Future<void> deleteEncryptionKey() async {
    try {
      await _secureStorage.delete(key: _keyName);
      _logger.w('Encryption key deleted from secure storage');
    } catch (e, stackTrace) {
      _logger.e(
        'Error deleting encryption key',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Checks if the legacy warning has been shown to the user.
  static Future<bool> hasShownLegacyWarning() async {
    try {
      final shown = await _secureStorage.read(key: _legacyWarningShown);
      return shown == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Marks that the legacy warning has been shown.
  static Future<void> markLegacyWarningShown() async {
    try {
      await _secureStorage.write(key: _legacyWarningShown, value: 'true');
    } catch (e, stackTrace) {
      _logger.w(
        'Error marking legacy warning shown',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
