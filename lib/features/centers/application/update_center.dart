import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/features/centers/domain/evacuation_center.dart';
import 'package:flutter/foundation.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';

final updateCenterCapacityProvider = Provider<UpdateCenterCapacity>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return UpdateCenterCapacity(databaseService: dbService);
});

class UpdateCenterCapacity {
  final DatabaseService _databaseService;

  UpdateCenterCapacity({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

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

      final centerRow = centerRows.first;
      centerRow['currentOccupancy'] = center.currentOccupancy;
      centerRow['status'] = _calculateUpdatedCenterStatus(
        center.currentOccupancy,
        center.totalCapacity,
      ).index;
      centerRow['lastUpdated'] = DateTime.now().toIso8601String();
      centerRow['synced'] = 0;

      await txn.update(
        'evacuation_centers',
        centerRow,
        where: 'id = ?',
        whereArgs: [center.id],
      );
      return true;
    });
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
