import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:kalig_onan_evac_system/core/indices/models_index.dart';
import 'package:kalig_onan_evac_system/services/database_service.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/features/centers/presentation/providers/evacuation_center_providers.dart';

final stationsByCenterProvider = FutureProvider.family<List<Station>, String>((
  ref,
  centerId,
) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getStationsForCenter(centerId);
});

final eligibleStationsProvider =
    FutureProvider.family<
      List<Station>,
      ({String centerId, AgeGroup ageGroup, MedicalCondition medicalCondition})
    >((ref, params) async {
      final db = ref.watch(databaseServiceProvider);
      return db.getEligibleStations(
        centerId: params.centerId,
        ageGroup: params.ageGroup,
        medicalCondition: params.medicalCondition,
      );
    });

final stationByIdProvider = FutureProvider.family<Station?, String>((
  ref,
  stationId,
) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getStationById(stationId);
});

extension StationDatabaseExtensions on DatabaseService {
  Future<void> insertStation(Station station) async {
    final db = await database;
    await db.insert(
      'stations',
      station.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncCenterCapacity(station.evacuationCenterId);
  }

  Future<void> updateStation(Station station) async {
    final db = await database;
    await db.update(
      'stations',
      station.copyWith(synced: false).toMap(),
      where: 'id = ?',
      whereArgs: [station.id],
    );
    await syncCenterCapacity(station.evacuationCenterId);
  }

  Future<void> deleteStation(String stationId) async {
    final db = await database;
    String? centerId;
    await db.transaction((txn) async {
      final stationRows = await txn.query(
        'stations',
        columns: ['evacuationCenterId'],
        where: 'id = ?',
        whereArgs: [stationId],
        limit: 1,
      );
      if (stationRows.isNotEmpty) {
        centerId = stationRows.first['evacuationCenterId'] as String;
      }

      await txn.update(
        'evacuees',
        {'stationId': null, 'synced': 0},
        where: 'stationId = ?',
        whereArgs: [stationId],
      );
      await txn.delete('stations', where: 'id = ?', whereArgs: [stationId]);
    });

    if (centerId != null) {
      await syncCenterCapacity(centerId!);
    }
  }

  Future<List<Station>> getStationsForCenter(String centerId) async {
    final db = await database;
    final maps = await db.query(
      'stations',
      where: 'evacuationCenterId = ?',
      whereArgs: [centerId],
      orderBy: 'name ASC',
    );
    return [for (final map in maps) Station.fromMap(map)];
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
          'evacuationCenterId = ? AND (allowedAgeGroup IS NULL OR allowedAgeGroup = ?) AND (allowedMedicalCondition IS NULL OR allowedMedicalCondition = ?)',
      whereArgs: [centerId, ageGroup.index, medicalCondition.index],
      orderBy: 'name ASC',
    );
    return [for (final map in maps) Station.fromMap(map)];
  }

  Future<Station?> getStationById(String stationId) async {
    final db = await database;
    final maps = await db.query(
      'stations',
      where: 'id = ?',
      whereArgs: [stationId],
      limit: 1,
    );
    return maps.isEmpty ? null : Station.fromMap(maps.first);
  }

  Future<List<Station>> getAllStations() async {
    final db = await database;
    final maps = await db.query('stations');
    return [for (final map in maps) Station.fromMap(map)];
  }

  Future<void> upsertStationFromRemote(Station station) async {
    final db = await database;
    await db.insert(
      'stations',
      station.copyWith(synced: true).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncCenterCapacity(station.evacuationCenterId);
  }

  Future<List<Station>> getUnsyncedStations() async {
    final db = await database;
    final maps = await db.query('stations', where: 'synced = 0');
    return [for (final map in maps) Station.fromMap(map)];
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
