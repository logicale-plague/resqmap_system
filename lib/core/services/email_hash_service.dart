import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailHashService {
  static final HashAlgorithm _algorithm = Sha256();

  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static Future<String> hashNormalizedEmail(String email) async {
    final normalizedEmail = normalizeEmail(email);
    final salt = dotenv.env['LOCAL_EMAIL_HASH_SALT']?.trim();
    if (salt == null || salt.isEmpty) {
      throw StateError(
        'Missing LOCAL_EMAIL_HASH_SALT. Configure it in the loaded environment.',
      );
    }

    final payload = utf8.encode('$salt:$normalizedEmail');
    final digest = await _algorithm.hash(payload);
    return base64UrlEncode(digest.bytes);
  }
}
