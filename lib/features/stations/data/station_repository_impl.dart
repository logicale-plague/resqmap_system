import 'package:kalig_onan_evac_system/features/centers/data/evacuation_center_repository_impl.dart';
import 'package:kalig_onan_evac_system/features/evacuees/domain/evacuee.dart';
import 'package:kalig_onan_evac_system/features/stations/data/station_dto.dart';
import 'package:kalig_onan_evac_system/features/stations/domain/station.dart';
import 'package:kalig_onan_evac_system/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

extension StationDatabaseExtensions on DatabaseService {
  Future<List<Station>> getStationsForCenter(String centerId) async {
    final db = await database;
    final maps = await db.query(
      'stations',
      where: 'evacuationCenterId = ?',
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
          'evacuationCenterId = ? AND (allowedAgeGroup IS NULL OR allowedAgeGroup = ? OR allowedAgeGroup = ?) AND (allowedMedicalCondition IS NULL OR allowedMedicalCondition = ? OR allowedMedicalCondition = ?)',
      whereArgs: [
        centerId,
        ageGroup.name,
        ageGroup.index,
        medicalCondition.name,
        medicalCondition.index,
      ],
      orderBy: 'name ASC',
    );
    return [for (final map in maps) stationFromMap(map)];
  }

  Future<Station?> getStationById(String stationId) async {
    final db = await database;
    final maps = await db.query(
      'stations',
      where: 'id = ?',
      whereArgs: [stationId],
      limit: 1,
    );
    return maps.isEmpty ? null : stationFromMap(maps.first);
  }

  Future<List<Station>> getAllStations() async {
    final db = await database;
    final maps = await db.query('stations');
    return [for (final map in maps) stationFromMap(map)];
  }

  Future<void> upsertStationFromRemote(Station station) async {
    final db = await database;
    await db.insert(
      'stations',
      stationToMap(station.copyWith(synced: true)),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncCenterCapacity(station.evacuationCenterId);
  }

  Future<List<Station>> getUnsyncedStations() async {
    final db = await database;
    final maps = await db.query('stations', where: 'synced = 0');
    return [for (final map in maps) stationFromMap(map)];
  }

  Future<void> markStationsSynced(List<String> ids) async {
    final db = await database;
    for (final id in ids) {
      await db.update(
        'stations',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
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
