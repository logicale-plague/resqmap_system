import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/supplies/data/supply_dto.dart';
import 'package:kalig_onan_evac_system/features/supplies/domain/supply.dart';

final updateSupplyProvider = Provider<UpdateSupplyUseCase>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return UpdateSupplyUseCase(databaseService: databaseService);
});

class UpdateSupplyUseCase {
  final DatabaseService _databaseService;

  UpdateSupplyUseCase({required DatabaseService databaseService})
    : _databaseService = databaseService;

  Future<void> updateSupply(Supply supply) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      final supplyRows = await txn.query(
        'supplies',
        where: 'id = ?',
        whereArgs: [supply.id],
      );

      if (supplyRows.isEmpty) {
        throw StateError('updateSupply could not find supplyId=${supply.id}.');
      }

      final supplyRow = supplyToRow(supply);
      supplyRow['synced'] = 0;

      await txn.update(
        'supplies',
        supplyRow,
        where: 'id = ?',
        whereArgs: [supply.id],
      );
    });
  }
}
