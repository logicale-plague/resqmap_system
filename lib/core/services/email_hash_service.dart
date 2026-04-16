import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:kalig_onan_evac_system/core/config/secrets.dart';

class EmailHashService {
  static final HashAlgorithm _algorithm = Sha256();

  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static Future<String> hashNormalizedEmail(String email) async {
    final normalizedEmail = normalizeEmail(email);
    final salt = Secrets.localSaltKey;
    if (salt.isEmpty) {
      throw StateError(
        'Missing LOCAL_EMAIL_HASH_SALT. Configure it in the loaded environment.',
      );
    }

    final payload = utf8.encode('$salt:$normalizedEmail');
    final digest = await _algorithm.hash(payload);
    return base64UrlEncode(digest.bytes);
  }
}
