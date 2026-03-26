import 'package:kalig_onan_evac_system/features/centers/domain/evacuation_center.dart';
import 'package:flutter/foundation.dart';
import 'package:kalig_onan_evac_system/services/database_service.dart';

extension UpdateCenterCapacityUseCase on DatabaseService {
  Future<bool> updateCenterOccupancy(String centerId, int newOccupancy) async {
    if (newOccupancy < 0) {
      throw ArgumentError.value(
        newOccupancy,
        'newOccupancy',
        'updateCenterOccupancy requires a non-negative occupancy.',
      );
    }

    final db = await database;
    final centerRows = await db.query(
      'evacuation_centers',
      columns: ['totalCapacity'],
      where: 'id = ?',
      whereArgs: [centerId],
      limit: 1,
    );
    if (centerRows.isEmpty) {
      debugPrint(
        'updateCenterOccupancy skipped: center not found (id=$centerId)',
      );
      return false;
    }

    final totalCapacity =
        (centerRows.first['totalCapacity'] as num?)?.toInt() ?? 0;
    final status = _calculateUpdatedCenterStatus(newOccupancy, totalCapacity);

    await db.update(
      'evacuation_centers',
      {
        'currentOccupancy': newOccupancy,
        'status': status.name,
        'synced': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [centerId],
    );

    return true;
  }
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

CenterStatus calculateCenterStatus(int currentOccupancy, int totalCapacity) {
  return _calculateUpdatedCenterStatus(currentOccupancy, totalCapacity);
}
