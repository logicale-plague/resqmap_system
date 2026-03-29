import 'package:kalig_onan_evac_system/features/staff/supplies/application/add_supply.dart';
import 'package:kalig_onan_evac_system/features/staff/supplies/application/update_supply.dart';
import 'package:kalig_onan_evac_system/features/staff/supplies/data/supply_db_extension.dart';
import 'package:kalig_onan_evac_system/features/staff/supplies/domain/supply.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/staff/supplies/domain/supply_repository.dart';

class SupplyRepositoryImpl implements SupplyRepository {
  final DatabaseService _databaseService;
  final AddSupplyUseCase _addSupply;
  final UpdateSupplyUseCase _updateSupply;

  SupplyRepositoryImpl(
    this._databaseService, {
    required AddSupplyUseCase addSupply,
    required UpdateSupplyUseCase updateSupply,
  }) : _addSupply = addSupply,
       _updateSupply = updateSupply;

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
  Future<void> update(Supply supply) => _updateSupply.updateSupply(supply);

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
