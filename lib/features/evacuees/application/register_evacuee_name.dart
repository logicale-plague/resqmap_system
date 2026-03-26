import 'package:kalig_onan_evac_system/core/services/database_service.dart';

extension RegisterEvacueeNameUseCase on DatabaseService {
  Future<void> registerEvacueeName(String evacueeId, String name) async {
    final finalName = name.trim();
    if (finalName.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'registerEvacueeName requires a non-empty trimmed name.',
      );
    }

    final db = await database;
    final affectedRows = await db.update(
      'evacuees',
      {'name': finalName, 'synced': 0},
      where: 'id = ?',
      whereArgs: [evacueeId],
    );

    if (affectedRows == 0) {
      throw StateError(
        'registerEvacueeName could not find evacueeId=$evacueeId.',
      );
    }
  }
}
