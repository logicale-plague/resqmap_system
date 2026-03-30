import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class PasswordHasher {
  static const _algorithmName = 'pbkdf2_sha256';
  static const _iterations = 100000;
  static const _maxIterations = 10000000;
  static const _saltLength = 16;
  static const _keyLength = 32;

  static final _algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _iterations,
    bits: _keyLength * 8,
  );

  static Future<String> hashPassword(String password) async {
    final salt = _randomBytes(_saltLength);
    final secretKey = await _algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final hashBytes = await secretKey.extractBytes();

    return [
      _algorithmName,
      _iterations.toString(),
      base64Encode(salt),
      base64Encode(hashBytes),
    ].join(r'$');
  }

  static Future<bool> verifyPassword({
    required String password,
    required String storedHash,
  }) async {
    final parts = storedHash.split(r'$');
    if (parts.length != 4) {
      return false;
    }
    if (parts[0] != _algorithmName) {
      return false;
    }

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0 || iterations > _maxIterations) {
      return false;
    }

    final salt = _tryDecodeBase64(parts[2]);
    final expectedHash = _tryDecodeBase64(parts[3]);
    if (salt == null || expectedHash == null) {
      return false;
    }

    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: expectedHash.length * 8,
    );
    final derivedKey = await algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final actualHash = await derivedKey.extractBytes();

    return _constantTimeEquals(actualHash, expectedHash);
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static List<int>? _tryDecodeBase64(String value) {
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
