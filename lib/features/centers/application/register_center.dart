import 'package:kalig_onan_evac_system/features/centers/data/evacuation_center_dto.dart';
import 'package:kalig_onan_evac_system/features/centers/domain/evacuation_center.dart';
import 'package:kalig_onan_evac_system/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

extension RegisterCenterUseCase on DatabaseService {
  Future<void> registerCenter(EvacuationCenter center) async {
    final db = await database;
    await db.insert(
      'evacuation_centers',
      centerToMap(center),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
