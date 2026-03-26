import 'package:kalig_onan_evac_system/features/supplies/data/supply_dto.dart';
import 'package:kalig_onan_evac_system/features/supplies/domain/supply.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

extension SupplyDatabaseExtensions on DatabaseService {
  Future<List<Supply>> getAllSupplies() async {
    final db = await database;
    final maps = await db.query('supplies');
    return [for (final map in maps) supplyFromRow(map)];
  }

  Future<List<Supply>> getSuppliesByCenterId(String centerId) async {
    final db = await database;
    final maps = await db.query(
      'supplies',
      where: 'evacuationCenterId = ?',
      whereArgs: [centerId],
    );
    return [for (final map in maps) supplyFromRow(map)];
  }

  Future<Supply?> getSupplyById(String id) async {
    final db = await database;
    final maps = await db.query(
      'supplies',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : supplyFromRow(maps.first);
  }

  Future<void> upsertSupplyFromRemote(Supply supply) async {
    final db = await database;
    await db.insert(
      'supplies',
      supplyToRow(supply.copyWith(synced: true)),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceSupplyId(String oldId, String newId) async {
    final db = await database;
    await db.transaction((txn) async {
      if (oldId != newId) {
        await txn.delete('supplies', where: 'id = ?', whereArgs: [newId]);
      }
      await txn.update(
        'supplies',
        {'id': newId, 'synced': 0},
        where: 'id = ?',
        whereArgs: [oldId],
      );
    });
  }

  Future<List<Supply>> getUnsyncedSupplies() async {
    final db = await database;
    final maps = await db.query('supplies', where: 'synced = 0');
    return [for (final map in maps) supplyFromRow(map)];
  }

  Future<void> markSuppliesSynced(List<String> ids) async {
    if (ids.isEmpty) return;

    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.rawUpdate(
      'UPDATE supplies SET synced = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }
}
