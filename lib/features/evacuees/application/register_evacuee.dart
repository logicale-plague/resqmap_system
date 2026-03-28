import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/features/centers/data/evacuation_center_db_extension.dart';
import 'package:kalig_onan_evac_system/features/evacuees/data/evacuee_dto.dart';
import 'package:kalig_onan_evac_system/features/evacuees/domain/evacuee.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

final registerEvacueeUseCaseProvider = Provider<RegisterEvacueeUseCase>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return RegisterEvacueeUseCase(databaseService: dbService);
});

class RegisterEvacueeUseCase {
  final DatabaseService _databaseService;

  RegisterEvacueeUseCase({required DatabaseService databaseService})
    : _databaseService = databaseService;

  Future<void> registerEvacuee(Evacuee evacuee) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      final row = evacueeToRow(evacuee);
      row['synced'] = 0;
      await txn.insert(
        'evacuees',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _databaseService.refreshCurrentCenterOccupancy(executor: txn);
    });
  }
}
