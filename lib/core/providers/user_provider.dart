import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/authentication/data/user_dto.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/core/services/user_pii_cipher.dart';
import 'package:sqflite/sqflite.dart';

final currentUserProvider = FutureProvider<User?>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getCurrentUser();
});

extension UserDatabaseExtensions on DatabaseService {
  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      'users',
      await userToLocalDbMap(user),
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
