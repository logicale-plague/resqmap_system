import 'package:kalig_onan_evac_system/features/evacuees/domain/evacuee.dart';

/// Abstract contract for evacuee persistence.
/// Implementations live in data/evacuee_repository_impl.dart.
abstract interface class EvacueeRepository {
  // READ Operations
  Future<List<Evacuee>> getAll({bool includeInactive = false});
  Future<Evacuee?> getById(String id);
  Future<int> getCount();
  Future<int> getCountByStation(String stationId);
  Future<List<Evacuee>> getEvacueesByStation(String stationId);
  Future<List<Evacuee>> getUnnamedByStation(String stationId);

  // WRITE Operations
  Future<void> insert(Evacuee evacuee);
  Future<void> update(Evacuee evacuee);
  Future<void> upsertFromRemote(Evacuee evacuee);
  Future<void> unassignEvacueesFromStation(String stationId);
  Future<void> markSynced(List<String> ids);
  Future<void> replaceId(String oldId, String newId);
}
