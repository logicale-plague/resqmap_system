import 'package:kalig_onan_evac_system/features/centers/domain/evacuation_center.dart';
import 'package:kalig_onan_evac_system/services/database_service.dart';

extension UpdateCenterCapacityUseCase on DatabaseService {
  Future<void> updateCenterOccupancy(String centerId, int newOccupancy) async {
    final db = await database;
    final centerRows = await db.query(
      'evacuation_centers',
      columns: ['totalCapacity'],
      where: 'id = ?',
      whereArgs: [centerId],
      limit: 1,
    );
    if (centerRows.isEmpty) return;

    final totalCapacity = centerRows.first['totalCapacity'] as int;
    final status = _calculateUpdatedCenterStatus(newOccupancy, totalCapacity);

    await db.update(
      'evacuation_centers',
      {
        'currentOccupancy': newOccupancy,
        'status': status.index,
        'synced': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [centerId],
    );
  }
}

CenterStatus _calculateUpdatedCenterStatus(int currentOccupancy, int totalCapacity) {
  if (totalCapacity <= 0) {
    return CenterStatus.operational;
  }

  final percentage = currentOccupancy / totalCapacity * 100;
  if (percentage >= 100) return CenterStatus.atCapacity;
  if (percentage >= 80) return CenterStatus.nearCapacity;
  return CenterStatus.operational;
}
