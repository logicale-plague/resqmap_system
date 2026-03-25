import 'package:kalig_onan_evac_system/services/database_service.dart';

extension UpdateSupplyStockUseCase on DatabaseService {
  Future<void> updateSupplyStock(String supplyId, int newStock) async {
    final db = await database;
    await db.update(
      'supplies',
      {'currentStock': newStock, 'synced': 0},
      where: 'id = ?',
      whereArgs: [supplyId],
    );
  }
}
