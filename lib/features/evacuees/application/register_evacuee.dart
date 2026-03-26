import 'package:kalig_onan_evac_system/features/centers/data/evacuation_center_repository_impl.dart';
import 'package:kalig_onan_evac_system/features/evacuees/data/evacuee_dto.dart';
import 'package:kalig_onan_evac_system/features/evacuees/domain/evacuee.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

extension RegisterEvacueeUseCase on DatabaseService {
  Future<void> insertEvacuee(Evacuee evacuee) async {
    final db = await database;
    await db.transaction((txn) async {
      final row = evacueeToRow(evacuee);
      row['synced'] = 0;
      await txn.insert(
        'evacuees',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await refreshCurrentCenterOccupancy(executor: txn);
    });
  }
}
