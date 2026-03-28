import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/stations/data/station_dto.dart';
import 'package:kalig_onan_evac_system/features/stations/domain/station.dart';

final updateStationProvider = Provider<UpdateStationUseCase>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return UpdateStationUseCase(databaseService: databaseService);
});

class UpdateStationUseCase {
  final DatabaseService _databaseService;

  UpdateStationUseCase({required DatabaseService databaseService})
    : _databaseService = databaseService;

  Future<void> updateStation(Station station) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      final stationRows = await txn.query(
        'stations',
        where: 'id = ?',
        whereArgs: [station.id],
      );

      if (stationRows.isEmpty) {
        throw StateError(
          'updateStation could not find stationId=${station.id}.',
        );
      }

      final stationRow = stationToMap(station);
      stationRow['active'] = station.active ? 1 : 0;
      stationRow['synced'] = 0;

      await txn.update(
        'stations',
        stationRow,
        where: 'id = ?',
        whereArgs: [station.id],
      );

      // Auto-unassign evacuees if station is deactivated
      if (!station.active) {
        await txn.update(
          'evacuees',
          {'stationId': null, 'synced': 0},
          where: 'stationId = ?',
          whereArgs: [station.id],
        );
      }
    });
  }
}
