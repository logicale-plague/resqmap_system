import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/authentication/data/user_dto.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/core/services/password_hasher.dart';
import 'package:kalig_onan_evac_system/core/services/user_pii_cipher.dart';
import 'package:sqflite/sqflite.dart';

final currentUserProvider = FutureProvider<User?>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getCurrentUser();
});

class LocalAuthUser {
  final User user;
  final String? passwordHash;

  const LocalAuthUser({required this.user, required this.passwordHash});
}

extension UserDatabaseExtensions on DatabaseService {
  Future<void> insertUser(User user, {String? password}) async {
    final db = await database;
    String? passwordHash;

    if (password != null && password.isNotEmpty) {
      passwordHash = await PasswordHasher.hashPassword(password);
    } else {
      final existing = await db.query(
        'users',
        columns: ['passwordHash'],
        where: 'id = ?',
        whereArgs: [user.id],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        passwordHash = existing.first['passwordHash'] as String?;
      }
    }

    await db.insert(
      'users',
      await userToLocalDbMap(user, passwordHash: passwordHash),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearCurrentUser() async {
    final db = await database;
    await db.delete('users');
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
    final maps = await db.query('users');
    if (maps.isEmpty) {
      return null;
    }

    final piiCipher = UserPiiCipher.instance();
    final normalizedTargetEmail = email.trim().toLowerCase();

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
      if (user.email.trim().toLowerCase() == normalizedTargetEmail) {
        return LocalAuthUser(
          user: user,
          passwordHash: userMap['passwordHash'] as String?,
        );
      }
    }

    return null;
  }

  Future<User?> verifyLocalUserCredentials(
    String email,
    String password,
  ) async {
    final localAuthUser = await getLocalAuthUserByEmail(email);
    if (localAuthUser == null) {
      return null;
    }

    final passwordHash = localAuthUser.passwordHash;
    if (passwordHash == null || passwordHash.isEmpty) {
      return null;
    }

    final isValid = await PasswordHasher.verifyPassword(
      password: password,
      storedHash: passwordHash,
    );
    return isValid ? localAuthUser.user : null;
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
