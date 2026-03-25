import 'package:kalig_onan_evac_system/features/centers/data/evacuation_center_repository_impl.dart';
import 'package:kalig_onan_evac_system/features/stations/data/station_dto.dart';
import 'package:kalig_onan_evac_system/features/stations/domain/station.dart';
import 'package:kalig_onan_evac_system/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

extension ManageStation on DatabaseService {
  Future<void> insertStation(Station station) async {
    final db = await database;
    await db.insert(
      'stations',
      stationToMap(station),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await syncCenterCapacity(station.evacuationCenterId);
  }

  Future<void> updateStation(Station station) async {
    final db = await database;
    await db.update(
      'stations',
      stationToMap(station.copyWith(synced: false)),
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
}
