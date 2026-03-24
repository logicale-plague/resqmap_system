import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../models/evacuee.dart';
import '../services/database_service.dart';
import 'database_provider.dart';
import 'evacuation_center_providers.dart';

final allEvacueesProvider = FutureProvider<List<Evacuee>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAllEvacuees();
});

final evacueeCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getEvacueeCount();
});

final unsyncedEvacueesProvider = FutureProvider<List<Evacuee>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getUnsyncedEvacuees();
});

final evacueeProvider = FutureProvider.family<Evacuee?, String>((
  ref,
  id,
) async {
  final db = ref.watch(databaseServiceProvider);
  final evacuees = await db.getAllEvacuees();
  try {
    return evacuees.firstWhere((e) => e.id == id);
  } catch (e) {
    return null;
  }
});

final unnamedEvacueesByStationProvider =
    FutureProvider.family<List<Evacuee>, String>((ref, stationId) async {
      final db = ref.watch(databaseServiceProvider);
      return db.getUnnamedEvacueesByStation(stationId);
    });

final evacueeCountByStationProvider = FutureProvider.family<int, String>((
  ref,
  stationId,
) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getEvacueeCountByStation(stationId);
});

extension EvacueeDatabaseExtensions on DatabaseService {
  Future<void> insertEvacuee(Evacuee evacuee) async {
    final db = await database;
    await db.insert(
      'evacuees',
      evacuee.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await refreshCurrentCenterOccupancy();
  }

  Future<List<Evacuee>> getUnnamedEvacueesByStation(String stationId) async {
    final db = await database;
    final maps = await db.query(
      'evacuees',
      where: 'stationId = ? AND active = 1 AND (name IS NULL OR TRIM(name) = "")',
      whereArgs: [stationId],
      orderBy: 'registeredAt ASC',
    );
    return [for (final map in maps) Evacuee.fromMap(map)];
  }

  Future<void> registerEvacueeName(String evacueeId, String name) async {
    final db = await database;
    await db.update(
      'evacuees',
      {'name': name.trim(), 'synced': 0},
      where: 'id = ?',
      whereArgs: [evacueeId],
    );
  }

  Future<List<Evacuee>> getAllEvacuees({bool includeInactive = false}) async {
    final db = await database;
    final maps = includeInactive
        ? await db.query('evacuees')
        : await db.query('evacuees', where: 'active = 1');
    return [for (final map in maps) Evacuee.fromMap(map)];
  }

  Future<int> getEvacueeCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM evacuees WHERE active = 1',
    );
    return int.parse(result.first['count'].toString());
  }

  Future<int> getEvacueeCountByStation(String stationId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM evacuees WHERE stationId = ? AND active = 1',
      [stationId],
    );
    return int.parse(result.first['count'].toString());
  }

  Future<Evacuee?> getEvacueeById(String id) async {
    final db = await database;
    final maps = await db.query(
      'evacuees',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : Evacuee.fromMap(maps.first);
  }

  Future<void> upsertEvacueeFromRemote(Evacuee evacuee) async {
    final db = await database;
    await db.insert(
      'evacuees',
      evacuee.copyWith(synced: true).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeEvacuee(String id) async {
    final db = await database;
    await db.update(
      'evacuees',
      {'active': 0, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshCurrentCenterOccupancy();
  }

  Future<List<Evacuee>> getUnsyncedEvacuees() async {
    final db = await database;
    final maps = await db.query('evacuees', where: 'synced = 0');
    return [for (final map in maps) Evacuee.fromMap(map)];
  }

  Future<void> markEvacueesSynced(List<String> ids) async {
    final db = await database;
    for (final id in ids) {
      await db.update(
        'evacuees',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> replaceEvacueeId(String oldId, String newId) async {
    final db = await database;
    await db.update(
      'evacuees',
      {'id': newId, 'synced': 0},
      where: 'id = ?',
      whereArgs: [oldId],
    );
  }
}
