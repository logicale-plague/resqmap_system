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
      final active = _readActiveFlag(row);

      await db.insert('user_cmd_centers', {
        'id': mappingId,
        'userId': mappedUserId,
        'commandCenterId': commandCenterId,
        'active': active ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getUserCommandCenterAccessRows(
    String userId, {
    bool includeInactive = false,
  }) async {
    final db = await database;
    final rows = await db.query(
      'user_cmd_centers',
      where: includeInactive ? 'userId = ?' : 'userId = ? AND active = 1',
      whereArgs: [userId],
    );
    return [for (final row in rows) Map<String, dynamic>.from(row)];
  }

  Future<List<String>> getUserCommandCenterIds(String userId) async {
    final rows = await getUserCommandCenterAccessRows(userId);
    return rows
        .map((row) => row['commandCenterId']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> setUserCommandCenterAccessActive(
    String userId,
    String commandCenterId,
    bool active, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;
    await db.update(
      'user_cmd_centers',
      {'active': active ? 1 : 0},
      where: 'userId = ? AND commandCenterId = ?',
      whereArgs: [userId, commandCenterId],
    );
  }

  Future<void> deleteUserCommandCenterAccessRow(
    String userId,
    String commandCenterId, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;
    await db.delete(
      'user_cmd_centers',
      where: 'userId = ? AND commandCenterId = ?',
      whereArgs: [userId, commandCenterId],
    );
  }

  Future<void> replaceUserEvacCenterAccess(
    String userId,
    List<Map<String, dynamic>> accessRows, {
    DatabaseExecutor? executor,
  }) async {
    if (executor != null) {
      await _replaceUserEvacCenterAccessOnExecutor(
        executor,
        userId,
        accessRows,
      );
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      await _replaceUserEvacCenterAccessOnExecutor(txn, userId, accessRows);
    });
  }

  Future<void> _replaceUserEvacCenterAccessOnExecutor(
    DatabaseExecutor db,
    String userId,
    List<Map<String, dynamic>> accessRows,
  ) async {
    await db.delete(
      'user_evac_centers',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    for (final row in accessRows) {
      final mappedUserId = (row['userId'] ?? row['user_id'] ?? userId)
          .toString();
      final evacuationCenterId =
          (row['evacuationCenterId'] ??
                  row['evacuation_center_id'] ??
                  row['evac_center_id'])
              ?.toString();
      if (evacuationCenterId == null || evacuationCenterId.isEmpty) {
        continue;
      }

      final mappingId =
          (row['id'] ?? row['mapping_id'])?.toString() ??
          '$mappedUserId::$evacuationCenterId';
      final active = _readActiveFlag(row);

      await db.insert('user_evac_centers', {
        'id': mappingId,
        'userId': mappedUserId,
        'evacuationCenterId': evacuationCenterId,
        'active': active ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getUserEvacuationCenterAccessRows(
    String userId, {
    bool includeInactive = false,
  }) async {
    final db = await database;
    final rows = await db.query(
      'user_evac_centers',
      where: includeInactive ? 'userId = ?' : 'userId = ? AND active = 1',
      whereArgs: [userId],
    );
    return [for (final row in rows) Map<String, dynamic>.from(row)];
  }

  Future<List<String>> getUserEvacuationCenterIds(String userId) async {
    final rows = await getUserEvacuationCenterAccessRows(userId);
    return rows
        .map((row) => row['evacuationCenterId']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> setUserEvacuationCenterAccessActive(
    String userId,
    String evacuationCenterId,
    bool active, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;
    await db.update(
      'user_evac_centers',
      {'active': active ? 1 : 0},
      where: 'userId = ? AND evacuationCenterId = ?',
      whereArgs: [userId, evacuationCenterId],
    );
  }

  Future<void> deleteUserEvacuationCenterAccessRow(
    String userId,
    String evacuationCenterId, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;
    await db.delete(
      'user_evac_centers',
      where: 'userId = ? AND evacuationCenterId = ?',
      whereArgs: [userId, evacuationCenterId],
    );
  }

  bool _readActiveFlag(Map<String, dynamic> row) {
    final rawActive = row['active'] ?? row['is_active'] ?? 1;
    if (rawActive is bool) {
      return rawActive;
    }
    if (rawActive is num) {
      return rawActive.toInt() == 1;
    }
    if (rawActive is String) {
      return rawActive == '1' || rawActive.toLowerCase() == 'true';
    }
    return true;
  }
}
