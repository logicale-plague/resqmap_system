import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../models/supply.dart';
import '../services/database_service.dart';
import 'database_provider.dart';

final allSuppliesProvider = FutureProvider<List<Supply>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAllSupplies();
});

final unsyncedSuppliesProvider = FutureProvider<List<Supply>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getUnsyncedSupplies();
});

final supplyProvider = FutureProvider.family<Supply?, String>((ref, id) async {
  final db = ref.watch(databaseServiceProvider);
  final supplies = await db.getAllSupplies();
  try {
    return supplies.firstWhere((s) => s.id == id);
  } catch (e) {
    return null;
  }
});

final lowStockSuppliesProvider = FutureProvider<List<Supply>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final supplies = await db.getAllSupplies();
  return supplies
      .where((s) => s.currentStock < (s.usageRatePerDay * 7))
      .toList();
});

extension SupplyDatabaseExtensions on DatabaseService {
  Future<void> insertSupply(Supply supply) async {
    final db = await database;
    await db.insert(
      'supplies',
      supply.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Supply>> getAllSupplies() async {
    final db = await database;
    final maps = await db.query('supplies');
    return [for (final map in maps) Supply.fromMap(map)];
  }

  Future<Supply?> getSupplyById(String id) async {
    final db = await database;
    final maps = await db.query(
      'supplies',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : Supply.fromMap(maps.first);
  }

  Future<void> upsertSupplyFromRemote(Supply supply) async {
    final db = await database;
    await db.insert(
      'supplies',
      supply.copyWith(synced: true).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceSupplyId(String oldId, String newId) async {
    final db = await database;
    await db.update(
      'supplies',
      {'id': newId, 'synced': 0},
      where: 'id = ?',
      whereArgs: [oldId],
    );
  }

  Future<void> updateSupplyStock(String supplyId, int newStock) async {
    final db = await database;
    await db.update(
      'supplies',
      {'currentStock': newStock, 'synced': 0},
      where: 'id = ?',
      whereArgs: [supplyId],
    );
  }

  Future<List<Supply>> getUnsyncedSupplies() async {
    final db = await database;
    final maps = await db.query('supplies', where: 'synced = 0');
    return [for (final map in maps) Supply.fromMap(map)];
  }

  Future<void> markSuppliesSynced(List<String> ids) async {
    final db = await database;
    for (final id in ids) {
      await db.update(
        'supplies',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
