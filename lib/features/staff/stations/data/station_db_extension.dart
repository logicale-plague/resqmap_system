import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/staff/centers/data/evacuation_center_db_extension.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/domain/evacuee.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/data/station_dto.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/domain/station.dart';
import 'package:sqflite/sqflite.dart';

extension StationDatabaseExtensions on DatabaseService {
  Future<List<Station>> getStationsForCenter(String centerId) async {
    final db = await database;
    final maps = await db.query(
      'stations',
      where: 'evacuationCenterId = ? AND active = 1',
      whereArgs: [centerId],
      orderBy: 'name ASC',
    );
    return [for (final map in maps) stationFromMap(map)];
  }

  Future<List<Station>> getEligibleStations({
    required String centerId,
    required AgeGroup ageGroup,
    required MedicalCondition medicalCondition,
  }) async {
    final db = await database;
    final maps = await db.query(
      'stations',
      where:
          'evacuationCenterId = ? AND (allowedAgeGroup IS NULL OR allowedAgeGroup = ?) AND (allowedMedicalCondition IS NULL OR allowedMedicalCondition = ?) AND active = 1',
      whereArgs: [centerId, ageGroup.index, medicalCondition.index],
      orderBy: 'name ASC',
    );
    return [for (final map in maps) stationFromMap(map)];
  }

  Future<Station?> getStationById(String stationId) async {
    final db = await database;
    final maps = await db.query(
      'stations',
      where: 'id = ? AND active = 1',
      whereArgs: [stationId],
      limit: 1,
    );
    return maps.isEmpty ? null : stationFromMap(maps.first);
  }

  Future<List<Station>> getAllStations() async {
    final db = await database;
    final maps = await db.query('stations', where: 'active = 1');
    return [for (final map in maps) stationFromMap(map)];
  }

  Future<void> upsertStationFromRemote(Station station) async {
    final db = await database;
    await db.transaction((txn) async {
      final existingRows = await txn.query(
        'stations',
        columns: ['evacuationCenterId'],
        where: 'id = ?',
        whereArgs: [station.id],
        limit: 1,
      );
      final previousCenterId = existingRows.isEmpty
          ? null
          : existingRows.first['evacuationCenterId'] as String?;

      await txn.insert(
        'stations',
        stationToMap(station.copyWith(synced: true)),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (previousCenterId != null &&
          previousCenterId != station.evacuationCenterId) {
        await syncCenterCapacity(previousCenterId, executor: txn);
      }
      await syncCenterCapacity(station.evacuationCenterId, executor: txn);
    });
  }

  Future<List<Station>> getUnsyncedStations() async {
    final db = await database;
    final maps = await db.query('stations', where: 'synced = 0');
    return [for (final map in maps) stationFromMap(map)];
  }

  Future<void> markStationsSynced(List<String> ids) async {
    if (ids.isEmpty) return;

    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.rawUpdate(
      'UPDATE stations SET synced = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  Future<void> replaceStationId(String oldId, String newId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'stations',
        {'id': newId, 'synced': 0},
        where: 'id = ?',
        whereArgs: [oldId],
      );
      await txn.update(
        'evacuees',
        {'stationId': newId, 'synced': 0},
        where: 'stationId = ?',
        whereArgs: [oldId],
      );
    });
  }
}
