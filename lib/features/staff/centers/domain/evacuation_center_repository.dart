import 'package:kalig_onan_evac_system/features/staff/centers/domain/evacuation_center.dart';

abstract interface class EvacuationCenterRepository {
  // READ Operations
  Future<EvacuationCenter?> getCurrent();
  Future<List<EvacuationCenter>> getAll();
  Future<EvacuationCenter?> getById(String id);
  Future<String> getCurrentCommandCenterId();

  // WRITE Operations
  Future<void> insert(EvacuationCenter center);
  Future<void> upsertFromRemote(EvacuationCenter center);
  Future<void> markSynced(List<String> ids);
  Future<void> replaceId(String oldId, String newId);
  Future<void> update(EvacuationCenter center);
}
