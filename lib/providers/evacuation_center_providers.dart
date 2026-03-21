import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../models/evacuation_center.dart';
import '../services/database_service.dart';
import 'database_provider.dart';

final currentCenterProvider = FutureProvider<EvacuationCenter?>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getCurrentCenter();
});

final allCentersProvider = FutureProvider<List<EvacuationCenter>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAllCenters();
});

final unsyncedCentersProvider = FutureProvider<List<EvacuationCenter>>((
  ref,
) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getUnsyncedCenters();
});

final centerProvider = FutureProvider.family<EvacuationCenter?, String>((
  ref,
  id,
) async {
  final db = ref.watch(databaseServiceProvider);
  final centers = await db.getAllCenters();
  try {
    return centers.firstWhere((c) => c.id == id);
  } catch (e) {
    return null;
  }
});

extension EvacuationCenterDatabaseExtensions on DatabaseService {
  Future<void> insertEvacuationCenter(EvacuationCenter center) async {
    final db = await database;
    await db.insert(
      'evacuation_centers',
      center.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<EvacuationCenter?> getCurrentCenter() async {
    final db = await database;
    final maps = await db.query('evacuation_centers', limit: 1);
    return maps.isEmpty ? null : EvacuationCenter.fromMap(maps.first);
  }

  Future<List<EvacuationCenter>> getAllCenters() async {
    final db = await database;
    final maps = await db.query('evacuation_centers');
    return [for (final map in maps) EvacuationCenter.fromMap(map)];
  }

  Future<EvacuationCenter?> getCenterById(String id) async {
    final db = await database;
    final maps = await db.query(
      'evacuation_centers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : EvacuationCenter.fromMap(maps.first);
  }

  Future<void> upsertCenterFromRemote(EvacuationCenter center) async {
    final db = await database;
    await db.insert(
      'evacuation_centers',
      center.copyWith(synced: true).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCenterOccupancy(String centerId, int newOccupancy) async {
    final db = await database;
    final centerRows = await db.query(
      'evacuation_centers',
      columns: ['totalCapacity'],
      where: 'id = ?',
      whereArgs: [centerId],
      limit: 1,
    );
    if (centerRows.isEmpty) return;

    final totalCapacity = centerRows.first['totalCapacity'] as int;
    final status = _calculateCenterStatus(newOccupancy, totalCapacity);

    await db.update(
      'evacuation_centers',
      {
        'currentOccupancy': newOccupancy,
        'status': status.index,
        'lastUpdated': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [centerId],
    );
  }

  Future<void> replaceCenterId(String oldId, String newId) async {
    final db = await database;
    await db.update(
      'evacuation_centers',
      {
        'id': newId,
        'synced': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [oldId],
    );
    await db.update(
      'stations',
      {'evacuationCenterId': newId, 'synced': 0},
      where: 'evacuationCenterId = ?',
      whereArgs: [oldId],
    );
    await syncCenterCapacity(newId);
  }

  Future<void> syncCenterCapacity(String centerId) async {
    final db = await database;

    final capacityResult = await db.rawQuery(
      'SELECT COALESCE(SUM(capacity), 0) as totalCapacity FROM stations WHERE evacuationCenterId = ?',
      [centerId],
    );
    final totalCapacity =
        (capacityResult.first['totalCapacity'] as num?)?.toInt() ?? 0;

    final centerRows = await db.query(
      'evacuation_centers',
      columns: ['currentOccupancy'],
      where: 'id = ?',
      whereArgs: [centerId],
      limit: 1,
    );
    if (centerRows.isEmpty) return;

    final currentOccupancy = centerRows.first['currentOccupancy'] as int;
    final status = _calculateCenterStatus(currentOccupancy, totalCapacity);

    await db.update(
      'evacuation_centers',
      {
        'totalCapacity': totalCapacity,
        'status': status.index,
        'lastUpdated': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [centerId],
    );
  }

  Future<void> refreshCurrentCenterOccupancy() async {
    final db = await database;

    final centerRows = await db.query(
      'evacuation_centers',
      columns: ['id', 'totalCapacity'],
      limit: 1,
    );
    if (centerRows.isEmpty) return;

    final centerId = centerRows.first['id'] as String;
    final totalCapacity = centerRows.first['totalCapacity'] as int;

    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM evacuees',
    );
    final evacueeCount = int.parse(countResult.first['count'].toString());
    final status = _calculateCenterStatus(evacueeCount, totalCapacity);

    await db.update(
      'evacuation_centers',
      {
        'currentOccupancy': evacueeCount,
        'status': status.index,
        'lastUpdated': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [centerId],
    );
  }

  Future<List<EvacuationCenter>> getUnsyncedCenters() async {
    final db = await database;
    final maps = await db.query('evacuation_centers', where: 'synced = 0');
    return [for (final map in maps) EvacuationCenter.fromMap(map)];
  }

  Future<void> markCentersSynced(List<String> ids) async {
    final db = await database;
    for (final id in ids) {
      await db.update(
        'evacuation_centers',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}

CenterStatus _calculateCenterStatus(int currentOccupancy, int totalCapacity) {
  if (totalCapacity <= 0) {
    return CenterStatus.operational;
  }
  final percentage = (currentOccupancy / totalCapacity * 100);
  if (percentage >= 100) return CenterStatus.atCapacity;
  if (percentage >= 80) return CenterStatus.nearCapacity;
  return CenterStatus.operational;
}
