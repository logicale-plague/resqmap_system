import 'package:kalig_onan_evac_system/features/centers/data/evacuation_center_dto.dart';
import 'package:kalig_onan_evac_system/features/centers/domain/evacuation_center.dart';
import 'package:kalig_onan_evac_system/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

extension EvacuationCenterDatabaseExtensions on DatabaseService {
  Future<EvacuationCenter?> getCurrentCenter() async {
    final db = await database;
    final maps = await db.query('evacuation_centers', limit: 1);
    return maps.isEmpty ? null : centerFromMap(maps.first);
  }

  Future<List<EvacuationCenter>> getAllCenters() async {
    final db = await database;
    final maps = await db.query('evacuation_centers');
    return [for (final map in maps) centerFromMap(map)];
  }

  Future<EvacuationCenter?> getCenterById(String id) async {
    final db = await database;
    final maps = await db.query(
      'evacuation_centers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : centerFromMap(maps.first);
  }

  Future<void> upsertCenterFromRemote(EvacuationCenter center) async {
    final db = await database;
    await db.insert(
      'evacuation_centers',
      centerToMap(center.copyWith(synced: true)),
      conflictAlgorithm: ConflictAlgorithm.replace,
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
    await db.update(
      'supplies',
      {'evacuationCenterId': newId, 'synced': 0},
      where: 'evacuationCenterId = ?',
      whereArgs: [oldId],
    );
    await db.update(
      'alerts',
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

  Future<void> refreshCurrentCenterOccupancy({
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;

    final centerRows = await db.query(
      'evacuation_centers',
      columns: ['id', 'totalCapacity'],
      limit: 1,
    );
    if (centerRows.isEmpty) return;

    final centerId = centerRows.first['id'] as String;
    final totalCapacity = centerRows.first['totalCapacity'] as int;

    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM evacuees WHERE active = 1',
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
    return [for (final map in maps) centerFromMap(map)];
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
