import 'package:kalig_onan_evac_system/features/centers/data/evacuation_center.dart';

abstract interface class EvacuationCenterRepository {
  Future<EvacuationCenter?> getCurrent();
  Future<List<EvacuationCenter>> getAll();
  Future<EvacuationCenter?> getById(String id);
  Future<String> getCurrentCommandCenterId();
  Future<void> insert(EvacuationCenter center);
  Future<void> updateOccupancy(String centerId, int occupancy);
  Future<void> upsertFromRemote(EvacuationCenter center);
  Future<void> markSynced(List<String> ids);
  Future<void> replaceId(String oldId, String newId);
}
