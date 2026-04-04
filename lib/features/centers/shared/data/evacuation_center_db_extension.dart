import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/data/evacuation_center_dto.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';
import 'package:sqflite/sqflite.dart';

extension EvacuationCenterDatabaseExtensions on DatabaseService {
  Future<String?> getStoredCurrentCenterId({DatabaseExecutor? executor}) async {
    final db = executor ?? await database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['currentCenterId'],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setCurrentCenterId(
    String id, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;
    await db.insert('app_settings', {
      'key': 'currentCenterId',
      'value': id,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<EvacuationCenter?> getCurrentCenter() async {
    final centerId = await getStoredCurrentCenterId();
    if (centerId == null) return null;
    return getCenterById(centerId);
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
    await setCurrentCenterId(center.id);
  }

  Future<void> replaceCenterId(String oldId, String newId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'evacuation_centers',
        {
          'id': newId,
          'synced': 0,
          'lastUpdated': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [oldId],
      );
      final currentId = await getStoredCurrentCenterId(executor: txn);
      if (currentId == oldId) {
        await setCurrentCenterId(newId, executor: txn);
      }
      await txn.update(
        'stations',
        {'evacuationCenterId': newId, 'synced': 0},
        where: 'evacuationCenterId = ?',
        whereArgs: [oldId],
      );
      await txn.update(
        'supplies',
        {'evacuationCenterId': newId, 'synced': 0},
        where: 'evacuationCenterId = ?',
        whereArgs: [oldId],
      );
      await syncCenterCapacity(newId, executor: txn);
    });
  }

  Future<void> syncCenterCapacity(
    String centerId, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;

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

    final currentOccupancy =
        (centerRows.first['currentOccupancy'] as num?)?.toInt() ?? 0;
    final status = calculateUpdatedCenterStatus(
      currentOccupancy,
      totalCapacity,
    );

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

    final centerId = await getStoredCurrentCenterId(executor: db);
    if (centerId == null) return;

    final centerRows = await db.query(
      'evacuation_centers',
      columns: ['totalCapacity'],
      where: 'id = ?',
      whereArgs: [centerId],
      limit: 1,
    );
    if (centerRows.isEmpty) return;

    final totalCapacity =
        (centerRows.first['totalCapacity'] as num?)?.toInt() ?? 0;

    final countResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM evacuees e
      JOIN stations s ON s.id = e.stationId
      WHERE e.active = 1 and s.evacuationCenterId = ?
      ''',
      [centerId],
    );
    final evacueeCount = (countResult.first['count'] as num).toInt();
    final status = calculateUpdatedCenterStatus(evacueeCount, totalCapacity);

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
    if (ids.isEmpty) return;

    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.rawUpdate(
      'UPDATE evacuation_centers SET synced = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  CenterStatus _calculateUpdatedCenterStatus(
    int currentOccupancy,
    int totalCapacity,
  ) {
    if (totalCapacity <= 0) {
      return CenterStatus.operational;
    }

    final percentage = currentOccupancy / totalCapacity * 100;
    if (percentage >= 100) return CenterStatus.atCapacity;
    if (percentage >= 80) return CenterStatus.nearCapacity;
    return CenterStatus.operational;
  }

  CenterStatus calculateUpdatedCenterStatus(
    int currentOccupancy,
    int totalCapacity,
  ) {
    return _calculateUpdatedCenterStatus(currentOccupancy, totalCapacity);
  }
}
