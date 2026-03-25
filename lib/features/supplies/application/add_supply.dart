import 'package:kalig_onan_evac_system/features/supplies/data/supply_dto.dart';
import 'package:kalig_onan_evac_system/features/supplies/domain/supply.dart';
import 'package:kalig_onan_evac_system/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

extension AddSupplyUseCase on DatabaseService {
  Future<void> insertSupply(Supply supply) async {
    final db = await database;
    final row = supplyToRow(supply);
    row['synced'] = 0;
    await db.insert(
      'supplies',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
