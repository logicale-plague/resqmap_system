import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/stations/data/station_dto.dart';
import 'package:kalig_onan_evac_system/features/stations/domain/station.dart';

final updateStationProvider = Provider<UpdateStation>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return UpdateStation(databaseService: databaseService);
});

class UpdateStation {
  final DatabaseService _databaseService;

  UpdateStation({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

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
      stationRow['synced'] = 0;

      await txn.update(
        'stations',
        stationRow,
        where: 'id = ?',
        whereArgs: [station.id],
      );
    });
  }
}
