// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/utils/secure_key_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureKeyManager crypto', () {
    final deterministicKey = base64.encode(List<int>.generate(32, (i) => i));

    test('AES-GCM encrypt/decrypt roundtrip', () {
      final cipher = SecureKeyManager.aesEncryptForTest(
        'plain-key',
        deterministicKey,
      );
      final decrypted = SecureKeyManager.aesDecryptForTest(
        cipher,
        deterministicKey,
      );
      expect(decrypted, 'plain-key');
    });

    test('AES-GCM uses random IV (ciphertext differs)', () {
      final c1 = SecureKeyManager.aesEncryptForTest(
        'same-text',
        deterministicKey,
      );
      final c2 = SecureKeyManager.aesEncryptForTest(
        'same-text',
        deterministicKey,
      );
      expect(c1, isNot(equals(c2)));
    });

    test('XOR legacy encrypt/decrypt roundtrip', () {
      final cipher = SecureKeyManager.xorEncryptForTest(
        'legacy-key',
        deterministicKey,
      );
      final plain = SecureKeyManager.xorDecryptForTest(
        cipher,
        deterministicKey,
      );
      expect(plain, 'legacy-key');
    });
  });
}
