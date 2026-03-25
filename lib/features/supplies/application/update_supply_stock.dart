import 'package:kalig_onan_evac_system/services/database_service.dart';

extension UpdateSupplyStockUseCase on DatabaseService {
  Future<void> updateSupplyStock(String supplyId, int newStock) async {
    if (newStock < 0) {
      throw ArgumentError(
        'updateSupplyStock received invalid newStock=$newStock for supplyId=$supplyId. newStock must be >= 0.',
      );
    }

    final db = await database;
    await db.update(
      'supplies',
      {'currentStock': newStock, 'synced': 0},
      where: 'id = ?',
      whereArgs: [supplyId],
    );
  }
}
