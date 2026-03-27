import 'package:kalig_onan_evac_system/features/supplies/application/add_supply.dart';
import 'package:kalig_onan_evac_system/features/supplies/application/update_supply_stock.dart';
import 'package:kalig_onan_evac_system/features/supplies/data/supply_db_extension.dart';
import 'package:kalig_onan_evac_system/features/supplies/domain/supply.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/supplies/domain/supply_repository.dart';

class SupplyRepositoryImpl implements SupplyRepository {
  final DatabaseService _databaseService;
  final AddSupply _addSupply;
  final UpdateSupplyStock _updateSupplyStock;

  SupplyRepositoryImpl(
    this._databaseService, {
    AddSupply? addSupply,
    UpdateSupplyStock? updateSupplyStock,
  }) : _addSupply = addSupply ?? AddSupply(databaseService: _databaseService),
       _updateSupplyStock =
           updateSupplyStock ??
           UpdateSupplyStock(databaseService: _databaseService);

  @override
  Future<List<Supply>> getAll() => _databaseService.getAllSupplies();

  @override
  Future<List<Supply>> getByCenterId(String centerId) =>
      _databaseService.getSuppliesByCenterId(centerId);

  @override
  Future<Supply?> getById(String id) => _databaseService.getSupplyById(id);

  @override
  Future<List<Supply>> getLowStock(String centerId) async {
    final supplies = await _databaseService.getSuppliesByCenterId(centerId);
    return supplies
        .where((supply) => supply.currentStock < (supply.usageRatePerDay * 7))
        .toList();
  }

  @override
  Future<List<Supply>> getUnsynced() => _databaseService.getUnsyncedSupplies();

  @override
  Future<void> insert(Supply supply) => _addSupply.insertSupply(supply);

  @override
  Future<void> updateStock(String id, int newStock) =>
      _updateSupplyStock.updateSupplyStock(id, newStock);

  @override
  Future<void> upsertFromRemote(Supply supply) =>
      _databaseService.upsertSupplyFromRemote(supply);

  @override
  Future<void> markSynced(List<String> ids) =>
      _databaseService.markSuppliesSynced(ids);

  @override
  Future<void> replaceId(String oldId, String newId) =>
      _databaseService.replaceSupplyId(oldId, newId);
}
