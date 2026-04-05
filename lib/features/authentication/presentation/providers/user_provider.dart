import 'package:kalig_onan_evac_system/features/authentication/data/user_dto.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/core/providers/user_provider.dart'
    as core_user_provider;
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/core/services/email_hash_service.dart';
import 'package:kalig_onan_evac_system/core/services/password_hasher.dart';
import 'package:kalig_onan_evac_system/core/services/user_pii_cipher.dart';
import 'package:sqflite/sqflite.dart';

final currentUserProvider = core_user_provider.currentUserProvider;

class LocalAuthUser {
  final User user;
  final String? passwordHash;

  const LocalAuthUser({required this.user, required this.passwordHash});
}

enum LocalCredentialVerificationStatus {
  success,
  userNotFound,
  wrongPassword,
  missingCachedHash,
}

class LocalCredentialVerificationResult {
  final LocalCredentialVerificationStatus status;
  final User? user;

  const LocalCredentialVerificationResult._(this.status, this.user);

  const LocalCredentialVerificationResult.success(User user)
    : this._(LocalCredentialVerificationStatus.success, user);

  const LocalCredentialVerificationResult.userNotFound()
    : this._(LocalCredentialVerificationStatus.userNotFound, null);

  const LocalCredentialVerificationResult.wrongPassword()
    : this._(LocalCredentialVerificationStatus.wrongPassword, null);

  const LocalCredentialVerificationResult.missingCachedHash()
    : this._(LocalCredentialVerificationStatus.missingCachedHash, null);
}

extension UserDatabaseExtensions on DatabaseService {
  Future<User?> getUserById(String id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    final raw = maps.first;
    final piiCipher = UserPiiCipher.instance();
    final hasLegacyPlaintext =
        !_isEncryptedOrNull(raw['email'], piiCipher) ||
        !_isEncryptedOrNull(raw['dateOfBirth'], piiCipher) ||
        !_isEncryptedOrNull(raw['postalCode'], piiCipher) ||
        !_isEncryptedOrNull(raw['fullAddress'], piiCipher);

    if (hasLegacyPlaintext) {
      final encryptedMap = await rotateLocalUserPiiFields(
        raw,
        cipher: piiCipher,
      );
      await db.update(
        'users',
        encryptedMap,
        where: 'id = ?',
        whereArgs: [raw['id']],
      );
      return userFromLocalDbMap(encryptedMap, cipher: piiCipher);
    }

    return userFromLocalDbMap(raw, cipher: piiCipher);
  }

  Future<User?> getCurrentUser() async {
    final db = await database;
    final maps = await db.query('users', limit: 1);
    if (maps.isEmpty) {
      return null;
    }

    final raw = maps.first;
    final piiCipher = UserPiiCipher.instance();
    final hasLegacyPlaintext =
        !_isEncryptedOrNull(raw['email'], piiCipher) ||
        !_isEncryptedOrNull(raw['dateOfBirth'], piiCipher) ||
        !_isEncryptedOrNull(raw['postalCode'], piiCipher) ||
        !_isEncryptedOrNull(raw['fullAddress'], piiCipher);

    if (hasLegacyPlaintext) {
      final encryptedMap = await rotateLocalUserPiiFields(
        raw,
        cipher: piiCipher,
      );
      await db.update(
        'users',
        encryptedMap,
        where: 'id = ?',
        whereArgs: [raw['id']],
      );
      return userFromLocalDbMap(encryptedMap, cipher: piiCipher);
    }

    return userFromLocalDbMap(raw, cipher: piiCipher);
  }

  Future<User?> getUserByEmail(String email) async {
    final localAuthUser = await getLocalAuthUserByEmail(email);
    return localAuthUser?.user;
  }

  Future<LocalAuthUser?> getLocalAuthUserByEmail(String email) async {
    final db = await database;
    final piiCipher = UserPiiCipher.instance();
    final normalizedTargetEmail = EmailHashService.normalizeEmail(email);
    final targetEmailHash = await EmailHashService.hashNormalizedEmail(
      normalizedTargetEmail,
    );

    var maps = await db.query(
      'users',
      where: 'emailHash = ?',
      whereArgs: [targetEmailHash],
    );

    if (maps.isEmpty) {
      await _backfillMissingEmailHashes(db, piiCipher);
      maps = await db.query(
        'users',
        where: 'emailHash = ?',
        whereArgs: [targetEmailHash],
      );
      if (maps.isEmpty) {
        return null;
      }
    }

    for (final raw in maps) {
      final hasLegacyPlaintext =
          !_isEncryptedOrNull(raw['email'], piiCipher) ||
          !_isEncryptedOrNull(raw['dateOfBirth'], piiCipher) ||
          !_isEncryptedOrNull(raw['postalCode'], piiCipher) ||
          !_isEncryptedOrNull(raw['fullAddress'], piiCipher);

      Map<String, dynamic> userMap = raw;
      if (hasLegacyPlaintext) {
        userMap = await rotateLocalUserPiiFields(raw, cipher: piiCipher);
        await db.update(
          'users',
          userMap,
          where: 'id = ?',
          whereArgs: [raw['id']],
        );
      }
      final user = await userFromLocalDbMap(userMap, cipher: piiCipher);
      if (EmailHashService.normalizeEmail(user.email) ==
          normalizedTargetEmail) {
        return LocalAuthUser(
          user: user,
          passwordHash: userMap['passwordHash'] as String?,
        );
      }
    }

    return null;
  }

  Future<void> _backfillMissingEmailHashes(
    Database db,
    UserPiiCipher piiCipher,
  ) async {
    final missingHashRows = await db.query(
      'users',
      where: 'emailHash IS NULL OR emailHash = ?',
      whereArgs: [''],
    );

    for (final raw in missingHashRows) {
      final hasLegacyPlaintext =
          !_isEncryptedOrNull(raw['email'], piiCipher) ||
          !_isEncryptedOrNull(raw['dateOfBirth'], piiCipher) ||
          !_isEncryptedOrNull(raw['postalCode'], piiCipher) ||
          !_isEncryptedOrNull(raw['fullAddress'], piiCipher);

      if (hasLegacyPlaintext) {
        final rotatedMap = await rotateLocalUserPiiFields(
          raw,
          cipher: piiCipher,
        );
        await db.update(
          'users',
          rotatedMap,
          where: 'id = ?',
          whereArgs: [raw['id']],
        );
        continue;
      }

      final decryptedEmail = await piiCipher.decryptNullable(
        raw['email'] as String?,
      );
      if (decryptedEmail == null) {
        continue;
      }

      final emailHash = await EmailHashService.hashNormalizedEmail(
        decryptedEmail,
      );
      await db.update(
        'users',
        {'emailHash': emailHash},
        where: 'id = ?',
        whereArgs: [raw['id']],
      );
    }
  }

  Future<LocalCredentialVerificationResult> verifyLocalUserCredentialsDetailed(
    String email,
    String password,
  ) async {
    final localAuthUser = await getLocalAuthUserByEmail(email);
    if (localAuthUser == null) {
      return const LocalCredentialVerificationResult.userNotFound();
    }

    final passwordHash = localAuthUser.passwordHash;
    if (passwordHash == null || passwordHash.isEmpty) {
      return const LocalCredentialVerificationResult.missingCachedHash();
    }

    final isValid = await PasswordHasher.verifyPassword(
      password: password,
      storedHash: passwordHash,
    );
    if (!isValid) {
      return const LocalCredentialVerificationResult.wrongPassword();
    }

    return LocalCredentialVerificationResult.success(localAuthUser.user);
  }

  Future<User?> verifyLocalUserCredentials(
    String email,
    String password,
  ) async {
    final result = await verifyLocalUserCredentialsDetailed(email, password);
    return result.status == LocalCredentialVerificationStatus.success
        ? result.user
        : null;
  }

  bool _isEncryptedOrNull(Object? value, UserPiiCipher cipher) {
    if (value == null) {
      return true;
    }
    if (value is! String) {
      return false;
    }
    return cipher.isEncryptedPayload(value);
  }
}
