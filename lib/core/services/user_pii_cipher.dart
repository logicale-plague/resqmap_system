import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class UserPiiKeyStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class SecureStorageUserPiiKeyStore implements UserPiiKeyStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  const SecureStorageUserPiiKeyStore();

  @override
  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }
}

class InMemoryUserPiiKeyStore implements UserPiiKeyStore {
  final Map<String, String> _memory = <String, String>{};

  @override
  Future<String?> read(String key) async {
    return _memory[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _memory[key] = value;
  }
}

class UserPiiCipher {
  static UserPiiCipher? _singleton;

  factory UserPiiCipher.instance() {
    return _singleton ??= UserPiiCipher(
      keyStore: const SecureStorageUserPiiKeyStore(),
    );
  }

  UserPiiCipher({required UserPiiKeyStore keyStore}) : _keyStore = keyStore;

  static final RegExp _payloadPattern = RegExp(
    r'^enc:v(\d+):([^:]+):([^:]+):([^:]+)$',
  );

  static const String _activeKeyVersionKey = 'user_pii_active_key_version';
  static const String _keyPrefix = 'user_pii_key_v';
  static const int _keyLengthBytes = 32;
  static const int _nonceLengthBytes = 12;

  final UserPiiKeyStore _keyStore;
  final AesGcm _algorithm = AesGcm.with256bits();
  final Random _random = Random.secure();

  Future<int> getActiveKeyVersion() async {
    final existing = await _keyStore.read(_activeKeyVersionKey);
    if (existing != null) {
      final parsed = int.tryParse(existing);
      if (parsed != null && parsed > 0) {
        await _getOrCreateSecretKey(version: parsed);
        return parsed;
      }
    }

    await _keyStore.write(_activeKeyVersionKey, '1');
    await _getOrCreateSecretKey(version: 1);
    return 1;
  }

  Future<void> rotateToVersion(int newVersion) async {
    if (newVersion < 1) {
      throw ArgumentError.value(newVersion, 'newVersion', 'Must be >= 1');
    }
    await _getOrCreateSecretKey(version: newVersion);
    await _keyStore.write(_activeKeyVersionKey, newVersion.toString());
  }

  Future<void> rotateToNextVersion() async {
    final currentVersion = await getActiveKeyVersion();
    await rotateToVersion(currentVersion + 1);
  }

  Future<String?> encryptNullable(String? value) async {
    if (value == null) {
      return null;
    }

    final keyVersion = await getActiveKeyVersion();
    final secretKey = await _getOrCreateSecretKey(version: keyVersion);
    final nonce = _generateNonce();
    final secretBox = await _algorithm.encrypt(
      utf8.encode(value),
      secretKey: secretKey,
      nonce: nonce,
    );

    return 'enc:v$keyVersion:${base64UrlEncode(secretBox.nonce)}:${base64UrlEncode(secretBox.cipherText)}:${base64UrlEncode(secretBox.mac.bytes)}';
  }

  Future<String?> decryptNullable(String? value) async {
    if (value == null) {
      return null;
    }

    final match = _payloadPattern.firstMatch(value);
    if (match == null) {
      // Supports legacy plaintext rows so existing users can still be loaded.
      return value;
    }

    final keyVersion = int.parse(match.group(1)!);
    final nonce = base64Url.decode(match.group(2)!);
    final cipherText = base64Url.decode(match.group(3)!);
    final macBytes = base64Url.decode(match.group(4)!);

    final secretKey = await _getOrCreateSecretKey(version: keyVersion);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
    final clearText = await _algorithm.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(clearText);
  }

  bool isEncryptedPayload(String? value) {
    if (value == null) {
      return false;
    }
    return _payloadPattern.hasMatch(value);
  }

  Future<SecretKey> _getOrCreateSecretKey({required int version}) async {
    final keyName = '$_keyPrefix$version';
    final existing = await _keyStore.read(keyName);
    if (existing != null) {
      return SecretKey(base64Url.decode(existing));
    }

    final bytes = List<int>.generate(
      _keyLengthBytes,
      (_) => _random.nextInt(256),
      growable: false,
    );
    final encoded = base64UrlEncode(bytes);
    await _keyStore.write(keyName, encoded);
    return SecretKey(bytes);
  }

  List<int> _generateNonce() {
    return List<int>.generate(
      _nonceLengthBytes,
      (_) => _random.nextInt(256),
      growable: false,
    );
  }
}
