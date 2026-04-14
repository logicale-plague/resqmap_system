import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/data/evacuation_center_db_extension.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/data/evacuee_dto.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/data/station_dto.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/domain/station.dart';

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
        columns: ['id', 'evacuationCenterId'],
        where: 'id = ?',
        whereArgs: [station.id],
      );

      if (stationRows.isEmpty) {
        throw StateError(
          'updateStation could not find stationId=${station.id}.',
        );
      }

      final occupancyResult = await txn.rawQuery(
        'SELECT COUNT(*) AS count FROM evacuees WHERE stationId = ? AND active = 1',
        [station.id],
      );
      final activeEvacueeCount =
          (occupancyResult.first['count'] as num?)?.toInt() ?? 0;
      if (station.active && station.capacity < activeEvacueeCount) {
        throw StateError(
          'Station capacity cannot be lower than assigned evacuees ($activeEvacueeCount).',
        );
      }

      if (station.active) {
        final assignedEvacueeRows = await txn.query(
          'evacuees',
          where: 'stationId = ? AND active = 1',
          whereArgs: [station.id],
        );

        final ineligibleEvacuees = assignedEvacueeRows
            .map(evacueeFromRow)
            .where(
              (evacuee) => !station.allows(
                ageGroup: evacuee.ageGroup,
                medicalCondition: evacuee.medicalCondition,
              ),
            )
            .toList(growable: false);

        if (ineligibleEvacuees.isNotEmpty) {
          throw StateError(
            'Cannot update station filters. ${ineligibleEvacuees.length} assigned evacuee(s) no longer match this station\'s allowed age group/medical condition. Reassign or update those evacuees first.',
          );
        }
      }

      final stationRow = stationToMap(station);
      stationRow['active'] = station.active ? 1 : 0;
      stationRow['synced'] = 0;
      final previousCenterId = stationRows.first['evacuationCenterId']
          ?.toString();

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

      if (previousCenterId != null &&
          previousCenterId.isNotEmpty &&
          previousCenterId != station.evacuationCenterId) {
        await _databaseService.syncCenterCapacity(
          previousCenterId,
          executor: txn,
        );
      }
      await _databaseService.syncCenterCapacity(
        station.evacuationCenterId,
        executor: txn,
      );
    });
  }
}
