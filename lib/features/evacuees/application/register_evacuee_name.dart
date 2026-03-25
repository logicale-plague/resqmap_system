import 'package:kalig_onan_evac_system/services/database_service.dart';

extension RegisterEvacueeNameUseCase on DatabaseService {
  Future<void> registerEvacueeName(String evacueeId, String name) async {
    final db = await database;
    await db.update(
      'evacuees',
      {'name': name.trim(), 'synced': 0},
      where: 'id = ?',
      whereArgs: [evacueeId],
    );
  }
}
