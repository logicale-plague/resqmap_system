import 'package:kalig_onan_evac_system/features/evacuees/data/evacuee.dart';

/// Abstract contract for evacuee persistence.
/// Implementations live in data/evacuee_repository_impl.dart.
abstract interface class EvacueeRepository {
  Future<List<Evacuee>> getAll({bool includeInactive = false});
  Future<Evacuee?> getById(String id);
  Future<int> getCount();
  Future<int> getCountByStation(String stationId);
  Future<List<Evacuee>> getUnsyncedEvacuees();
  Future<List<Evacuee>> getByStation(String stationId);
  Future<List<Evacuee>> getUnnamedByStation(String stationId);
  Future<void> insert(Evacuee evacuee);
  Future<void> registerName(String evacueeId, String name);
  Future<void> remove(String id);
  Future<void> upsertFromRemote(Evacuee evacuee);
  Future<void> markSynced(List<String> ids);
  Future<void> replaceId(String oldId, String newId);
}
