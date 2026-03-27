import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/supplies/data/supply_dto.dart';
import 'package:kalig_onan_evac_system/features/supplies/domain/supply.dart';
import 'package:sqflite/sqflite.dart';

final addSupplyProvider = Provider<AddSupplyUseCase>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return AddSupplyUseCase(databaseService: databaseService);
});

class AddSupplyUseCase {
  final DatabaseService _databaseService;

  AddSupplyUseCase({required DatabaseService databaseService})
    : _databaseService = databaseService;

  Future<void> insertSupply(Supply supply) async {
    final db = await _databaseService.database;
    final row = supplyToRow(supply);
    row['synced'] = 0;
    await db.insert(
      'supplies',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
