import 'package:kalig_onan_evac_system/services/database_service.dart';

extension MarkAlertReadUseCase on DatabaseService {
  Future<void> markAlertAsRead(String alertId) async {
    final db = await database;
    await db.update(
      'alerts',
      {'read': 1, 'synced': 0},
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }
}
