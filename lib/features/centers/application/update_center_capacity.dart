import 'package:kalig_onan_evac_system/services/database_service.dart';

extension UpdateCenterCapacityUseCase on DatabaseService {
  Future<void> updateCenterOccupancy(String centerId, int newOccupancy) async {
    final db = await database;
    await db.update(
      'evacuation_centers',
      {
        'occupancy': newOccupancy,
        'synced': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [centerId],
    );
  }
}
