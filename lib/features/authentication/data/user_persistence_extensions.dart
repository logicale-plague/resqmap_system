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

  Future<void> replaceUserCommandCenterAccess(
    String userId,
    List<Map<String, dynamic>> accessRows, {
    DatabaseExecutor? executor,
  }) async {
    if (executor != null) {
      await _replaceUserCommandCenterAccessOnExecutor(
        executor,
        userId,
        accessRows,
      );
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      await _replaceUserCommandCenterAccessOnExecutor(txn, userId, accessRows);
    });
  }

  Future<void> _replaceUserCommandCenterAccessOnExecutor(
    DatabaseExecutor db,
    String userId,
    List<Map<String, dynamic>> accessRows,
  ) async {
    await db.delete(
      'user_cmd_centers',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    for (final row in accessRows) {
      final mappedUserId = (row['userId'] ?? row['user_id'] ?? userId)
          .toString();
      final commandCenterId =
          (row['commandCenterId'] ??
                  row['command_center_id'] ??
                  row['cmd_center_id'])
              ?.toString();
      if (commandCenterId == null || commandCenterId.isEmpty) {
        continue;
      }

      final mappingId =
          (row['id'] ?? row['mapping_id'])?.toString() ??
          '$mappedUserId::$commandCenterId';

      await db.insert('user_cmd_centers', {
        'id': mappingId,
        'userId': mappedUserId,
        'commandCenterId': commandCenterId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<String>> getUserCommandCenterIds(String userId) async {
    final db = await database;
    final rows = await db.query(
      'user_cmd_centers',
      columns: ['commandCenterId'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return rows
        .map((row) => row['commandCenterId']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }
}
