import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';

abstract interface class EvacuationCenterRepository {
  Future<EvacuationCenter?> getCurrent();
  Future<List<EvacuationCenter>> getAll();
  Future<List<EvacuationCenter>> getAllViaPostal();
  Future<List<EvacuationCenter>> getUnsynced();
  Future<List<EvacuationCenter>> getByCommandCenterId(String commandCenterId);
  Future<EvacuationCenter?> getById(String id);

  Future<void> insert(EvacuationCenter center);
  Future<void> upsertFromRemote(EvacuationCenter center);
  Future<void> markSynced(List<String> ids);
  Future<void> replaceId(String oldId, String newId);
  Future<void> update(EvacuationCenter center);
}
