import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

/// Manages secure encryption keys for the database.
///
/// This class implements a hybrid security approach:
/// 1. Primary: Random key stored in secure platform storage (best security)
/// 2. Backup: Random key encrypted with deterministic key in SharedPreferences
/// 3. Fallback: Deterministic key generation if both storage methods fail
///
/// Key features:
/// - Cryptographically random keys for maximum security
/// - Encrypted backup for reliability when secure storage fails
/// - Deterministic recovery as last resort
/// - Comprehensive logging for debugging (never logs actual key values)
/// - No hardcoded secrets in source code
class SecureKeyManager {
  static final _logger = AppLogger.getLogger('SecureKeyManager');
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyName = 'hr_db_encryption_key';
  static const _backupKeyName = 'hr_db_encryption_key_backup';
  static const _legacyWarningShown = 'legacy_warning_shown';

  /// Gets or creates the database encryption key using a hybrid approach.
  ///
  /// Recovery strategy (in order):
  /// 1. Try secure storage (primary - best security)
  /// 2. Try encrypted backup from SharedPreferences (fallback #1)
  /// 3. Try deterministic key from device ID (fallback #2 - existing DB)
  /// 4. Generate new random key (first time setup)
  ///
  /// Returns the encryption key as a base64-encoded string.
  static Future<String> getOrCreateEncryptionKey() async {
    _logger.i('Starting encryption key retrieval/generation process');

    try {
      // STEP 1: Try to retrieve from secure storage (primary)
      _logger.d('Step 1: Checking secure storage for primary key');
      final existingKey = await _secureStorage.read(key: _keyName);

      if (existingKey != null && existingKey.isNotEmpty) {
        // Log key hash for debugging (NOT the actual key)
        final keyHash = sha256.convert(utf8.encode(existingKey)).toString();
        final keyHashPrefix = keyHash.substring(0, 16);
        _logger.i(
          'SUCCESS: Retrieved key from secure storage (length: ${existingKey.length} chars, hash: $keyHashPrefix...)',
        );
        return existingKey;
      }
      _logger.w('Secure storage returned null or empty - attempting recovery');

      // STEP 2: Try encrypted backup from SharedPreferences
      _logger.d('Step 2: Attempting to recover key from encrypted backup');
      final recoveredKey = await _recoverKeyFromBackup();

      if (recoveredKey != null) {
        _logger.i(
          'SUCCESS: Recovered key from encrypted backup (length: ${recoveredKey.length} chars)',
        );
        // Re-store in secure storage for next time
        try {
          await _secureStorage.write(key: _keyName, value: recoveredKey);
          _logger.d('Re-stored recovered key in secure storage');
        } catch (e) {
          _logger.w('Failed to re-store key in secure storage: $e');
        }
        return recoveredKey;
      }
      _logger.w('Encrypted backup not found or decryption failed');

      // STEP 3: Check if this is first-time setup or migration
      final isFirstTime = await isFirstTimeSetup();

      if (isFirstTime) {
        // New installation - use random key for best security
        _logger.i('First-time setup detected - generating random key');
        final randomKey = _generateRandomKey();

        // Log key hash for debugging (NOT the actual key)
        final keyHash = sha256.convert(utf8.encode(randomKey)).toString();
        final keyHashPrefix = keyHash.substring(0, 16);
        _logger.i('Generated key hash: $keyHashPrefix...');

        // Store with encrypted backup
        await _storeKeyWithBackup(randomKey);
        _logger.i('Random key generated and stored with backup');

        return randomKey;
      } else {
        // Existing installation - try deterministic key (migration path)
        _logger.d(
          'Step 3: Existing installation - trying deterministic key for migration',
        );
        final deterministicKey = await _generateDeterministicKey();

        _logger.w(
          'Using deterministic key (length: ${deterministicKey.length} chars) - migrating from old version',
        );

        // Store this key for future use
        await _storeKeyWithBackup(deterministicKey);
        _logger.d('Stored deterministic key as primary key');

        return deterministicKey;
      }
    } catch (e, stackTrace) {
      _logger.e(
        'FATAL: Error in encryption key management',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Generates a deterministic encryption key based on device ID.
  ///
  /// This key is always the same for a given device, making it suitable for:
  /// - Recovery when secure storage fails
  /// - Encrypting backup keys
  /// - Migration from older app versions
  ///
  /// The key is derived from:
  /// - Device-specific identifier (Android ID, iOS identifierForVendor, etc.)
  /// - Application-specific constant (no random component)
  ///
  /// Security: Lower than random keys, but still protects against casual access.
  static Future<String> _generateDeterministicKey() async {
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

      // Use device ID with app-specific constant (no random salt)
      // This ensures the key is deterministic and can be regenerated if needed
      final keyMaterial = '$deviceId:hr_dashboard_v1_stable';

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

  /// Generates a cryptographically random encryption key.
  ///
  /// This provides the best security as the key cannot be derived from any
  /// device information. The key is 256 bits (32 bytes) of secure random data.
  ///
  /// Returns a base64-encoded random key.
  static String _generateRandomKey() {
    _logger.d('Generating new random encryption key');
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final randomKey = base64.encode(keyBytes);
    _logger.d('Random key generated (length: ${randomKey.length} chars)');
    return randomKey;
  }

  /// Stores a key in both secure storage and encrypted backup.
  ///
  /// This ensures the key can be recovered even if secure storage fails.
  ///
  /// Storage strategy:
  /// 1. Store plaintext key in secure storage (primary)
  /// 2. Encrypt key with deterministic key
  /// 3. Store encrypted key in SharedPreferences (backup)
  static Future<void> _storeKeyWithBackup(String key) async {
    _logger.d('Storing key with encrypted backup');

    // Log key hash for verification
    final keyHash = sha256.convert(utf8.encode(key)).toString();
    final keyHashPrefix = keyHash.substring(0, 16);
    _logger.d('Storing key with hash: $keyHashPrefix...');

    try {
      // Store in secure storage (primary)
      await _secureStorage.write(key: _keyName, value: key);
      _logger.d('Key stored in secure storage successfully');
    } catch (e) {
      _logger.w('Failed to store key in secure storage: $e');
      // Continue - backup storage might still work
    }

    try {
      // Create encrypted backup
      final deterministicKey = await _generateDeterministicKey();
      final encryptedKey = _encryptKey(key, deterministicKey);

      // Store in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupKeyName, encryptedKey);
      _logger.d(
        'Encrypted backup stored in SharedPreferences (length: ${encryptedKey.length} chars)',
      );
    } catch (e, stackTrace) {
      _logger.w(
        'Failed to create encrypted backup',
        error: e,
        stackTrace: stackTrace,
      );
      // Not fatal - primary storage might work
    }
  }

  /// Recovers the encryption key from encrypted backup.
  ///
  /// Attempts to read the encrypted backup from SharedPreferences and
  /// decrypt it using the deterministic device key.
  ///
  /// Returns the decrypted key, or null if backup doesn't exist or
  /// decryption fails.
  static Future<String?> _recoverKeyFromBackup() async {
    try {
      _logger.d('Attempting to read encrypted backup');

      // Read encrypted backup from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final encryptedKey = prefs.getString(_backupKeyName);

      if (encryptedKey == null || encryptedKey.isEmpty) {
        _logger.d('No encrypted backup found in SharedPreferences');
        return null;
      }

      _logger.d(
        'Found encrypted backup (length: ${encryptedKey.length} chars) - attempting decryption',
      );

      // Generate deterministic key for decryption
      final deterministicKey = await _generateDeterministicKey();

      // Decrypt the backup
      final decryptedKey = _decryptKey(encryptedKey, deterministicKey);

      if (decryptedKey == null) {
        _logger.w('Backup decryption failed - data may be corrupted');
        return null;
      }

      _logger.d(
        'Successfully decrypted backup (length: ${decryptedKey.length} chars)',
      );
      return decryptedKey;
    } catch (e, stackTrace) {
      _logger.w(
        'Error recovering key from backup',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Encrypts a key using XOR cipher with SHA-256 key derivation.
  ///
  /// This is a simple encryption that's sufficient for our use case since:
  /// - The encryption key is itself derived from device-specific data
  /// - The encrypted data is stored in app-private storage
  /// - We're not protecting against sophisticated attacks on the backup
  ///
  /// Returns base64-encoded encrypted data.
  static String _encryptKey(String plainKey, String encryptionKey) {
    final plainBytes = utf8.encode(plainKey);
    final keyHash = sha256.convert(utf8.encode(encryptionKey)).bytes;

    // XOR encryption
    final encryptedBytes = <int>[];
    for (int i = 0; i < plainBytes.length; i++) {
      encryptedBytes.add(plainBytes[i] ^ keyHash[i % keyHash.length]);
    }

    return base64.encode(encryptedBytes);
  }

  /// Decrypts a key that was encrypted with _encryptKey.
  ///
  /// Returns the decrypted key, or null if decryption fails.
  static String? _decryptKey(String encryptedKey, String decryptionKey) {
    try {
      final encryptedBytes = base64.decode(encryptedKey);
      final keyHash = sha256.convert(utf8.encode(decryptionKey)).bytes;

      // XOR decryption (same operation as encryption)
      final decryptedBytes = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ keyHash[i % keyHash.length]);
      }

      return utf8.decode(decryptedBytes);
    } catch (e) {
      _logger.w('Decryption failed: $e');
      return null;
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

  /// Checks if this is a first-time setup (no existing keys).
  ///
  /// Returns true if no encryption key exists in any storage location.
  /// This helps determine whether to generate a new random key or use
  /// a deterministic key for migration.
  static Future<bool> isFirstTimeSetup() async {
    try {
      // Check secure storage
      final existingKey = await _secureStorage.read(key: _keyName);
      if (existingKey != null && existingKey.isNotEmpty) {
        _logger.d('Found existing key in secure storage - not first time');
        return false;
      }

      // Check backup storage
      final prefs = await SharedPreferences.getInstance();
      final backup = prefs.getString(_backupKeyName);
      if (backup != null && backup.isNotEmpty) {
        _logger.d('Found encrypted backup - not first time');
        return false;
      }

      _logger.d('No existing keys found - first time setup');
      return true;
    } catch (e, stackTrace) {
      _logger.w(
        'Error checking first-time setup',
        error: e,
        stackTrace: stackTrace,
      );
      // Assume not first time if we can't check (safer for data preservation)
      return false;
    }
  }

  /// Deletes the encryption key from all storage locations.
  ///
  /// WARNING: This will make any encrypted database unrecoverable!
  /// Only use this for testing or user-initiated data deletion.
  ///
  /// Removes:
  /// - Key from secure storage
  /// - Encrypted backup from SharedPreferences
  static Future<void> deleteEncryptionKey() async {
    _logger.w('Deleting encryption key from all storage locations');

    try {
      // Delete from secure storage
      await _secureStorage.delete(key: _keyName);
      _logger.d('Deleted key from secure storage');
    } catch (e) {
      _logger.w('Error deleting from secure storage: $e');
    }

    try {
      // Delete encrypted backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_backupKeyName);
      _logger.d('Deleted encrypted backup from SharedPreferences');
    } catch (e) {
      _logger.w('Error deleting backup: $e');
    }

    _logger.w('Encryption key deletion complete');
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
