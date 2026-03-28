import 'package:kalig_onan_evac_system/features/supplies/domain/supply.dart';

abstract interface class SupplyRepository {
  // READ Operations
  Future<List<Supply>> getAll();
  Future<List<Supply>> getByCenterId(String centerId);
  Future<Supply?> getById(String id);
  Future<List<Supply>> getLowStock(String centerId);
  Future<List<Supply>> getUnsynced();

  // WRITE Operations
  Future<void> insert(Supply supply);
  Future<void> update(Supply supply);
  Future<void> upsertFromRemote(Supply supply);
  Future<void> markSynced(List<String> ids);
  Future<void> replaceId(String oldId, String newId);
}
