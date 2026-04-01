import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';

final updateCenterCapacityProvider = Provider<UpdateCenterUseCase>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return UpdateCenterUseCase(databaseService: dbService);
});

class UpdateCenterUseCase {
  final DatabaseService _databaseService;

  UpdateCenterUseCase({required DatabaseService databaseService})
    : _databaseService = databaseService;

  Future<bool> updateCenter(EvacuationCenter center) async {
    final db = await _databaseService.database;
    return await db.transaction((txn) async {
      final centerRows = await txn.query(
        'evacuation_centers',
        where: 'id = ?',
        whereArgs: [center.id],
      );

      if (centerRows.isEmpty) {
        debugPrint('updateCenter could not find centerId=${center.id}.');
        return false;
      }

      final updatedRow = Map<String, dynamic>.from(centerRows.first)
        ..['name'] = center.name
        ..['commandCenterId'] = center.commandCenterId
        ..['latitude'] = center.latitude
        ..['longitude'] = center.longitude
        ..['totalCapacity'] = center.totalCapacity
        ..['currentOccupancy'] = center.currentOccupancy
        ..['status'] = center.status == CenterStatus.closed
            ? center.status.name
            : calculateUpdatedCenterStatus(
                center.currentOccupancy,
                center.totalCapacity,
              ).name
        ..['medicalAvailable'] = center.medicalAvailable ? 1 : 0
        ..['lastUpdated'] = DateTime.now().toIso8601String()
        ..['synced'] = 0;

      await txn.update(
        'evacuation_centers',
        updatedRow,
        where: 'id = ?',
        whereArgs: [center.id],
      );
      return true;
    });
  }

  CenterStatus calculateUpdatedCenterStatus(
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
}
