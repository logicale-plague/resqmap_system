import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/core/services/password_hasher.dart';
import 'package:kalig_onan_evac_system/features/authentication/data/user_dto.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:sqflite/sqflite.dart';

extension UserPersistenceExtensions on DatabaseService {
  Future<void> insertUser(
    User user, {
    String? password,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;
    final passwordHash = await _resolvePasswordHash(
      db,
      userId: user.id,
      password: password,
    );
    await _insertUserRecord(db, user, passwordHash: passwordHash);
  }

  Future<void> replaceCurrentUser(User user, {String? password}) async {
    final db = await database;
    await db.transaction((txn) async {
      final passwordHash = await _resolvePasswordHash(
        txn,
        userId: user.id,
        password: password,
      );
      await clearCurrentUser(executor: txn);
      await _insertUserRecord(txn, user, passwordHash: passwordHash);
    });
  }

  Future<void> clearCurrentUser({DatabaseExecutor? executor}) async {
    final db = executor ?? await database;
    await db.delete('users');
  }

  Future<String?> _resolvePasswordHash(
    DatabaseExecutor db, {
    required String userId,
    String? password,
  }) async {
    if (password != null && password.isNotEmpty) {
      return PasswordHasher.hashPassword(password);
    }

    final existing = await db.query(
      'users',
      columns: ['passwordHash'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return existing.first['passwordHash'] as String?;
    }

    return null;
  }

  Future<void> _insertUserRecord(
    DatabaseExecutor db,
    User user, {
    required String? passwordHash,
  }) async {
    await db.insert(
      'users',
      await userToLocalDbMap(user, passwordHash: passwordHash),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
