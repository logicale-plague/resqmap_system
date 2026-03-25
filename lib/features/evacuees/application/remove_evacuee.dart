import 'package:kalig_onan_evac_system/features/centers/data/evacuation_center_repository_impl.dart';
import 'package:kalig_onan_evac_system/services/database_service.dart';

extension RemoveEvacueeUseCase on DatabaseService {
  Future<void> removeEvacuee(String id) async {
    final db = await database;
    await db.update(
      'evacuees',
      {'active': 0, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshCurrentCenterOccupancy();
  }
}
