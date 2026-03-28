import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/authentication/data/user_dto.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
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
      userToMap(user),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getCurrentUser() async {
    final db = await database;
    final maps = await db.query('users', limit: 1);
    return maps.isEmpty ? null : userFromMap(maps.first);
  }
}
