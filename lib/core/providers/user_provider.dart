import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/users/data/user.dart';
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
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getCurrentUser() async {
    final db = await database;
    final maps = await db.query('users', limit: 1);
    return maps.isEmpty ? null : User.fromMap(maps.first);
  }
}
