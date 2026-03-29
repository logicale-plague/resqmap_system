import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/features/staff/centers/data/evacuation_center_db_extension.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/data/evacuee_dto.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/domain/evacuee.dart';

final updateEvacueeProvider = Provider<UpdateEvacueeUseCase>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return UpdateEvacueeUseCase(databaseService: dbService);
});

class UpdateEvacueeUseCase {
  final DatabaseService _databaseService;

  UpdateEvacueeUseCase({required DatabaseService databaseService})
    : _databaseService = databaseService;

  Future<void> updateEvacuee(Evacuee evacuee) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      final evacueeRows = await txn.query(
        'evacuees',
        where: 'id = ?',
        whereArgs: [evacuee.id],
      );

      if (evacueeRows.isEmpty) {
        throw StateError(
          'updateEvacuee could not find evacueeId=${evacuee.id}.',
        );
      }

      final evacueeRow = evacueeToRow(evacuee);
      evacueeRow['synced'] = 0;

      await txn.update(
        'evacuees',
        evacueeRow,
        where: 'id = ?',
        whereArgs: [evacuee.id],
      );
      await _databaseService.refreshCurrentCenterOccupancy(executor: txn);
    });
  }
}
