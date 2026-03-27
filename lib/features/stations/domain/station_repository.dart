import 'package:kalig_onan_evac_system/features/stations/domain/station.dart';
import 'package:kalig_onan_evac_system/features/evacuees/domain/evacuee.dart';

abstract interface class StationRepository {
  // READ Operations
  Future<List<Station>> getAll();
  Future<List<Station>> getByCenter(String centerId);
  Future<Station?> getById(String id);
  Future<List<Station>> getEligible(
    String centerId,
    AgeGroup ageGroup,
    MedicalCondition condition,
  );

  // WRITE Operations
  Future<void> insert(Station station);
  Future<void> update(Station station);
  Future<void> delete(Station station);
  Future<void> upsertFromRemote(Station station);
  Future<void> markSynced(List<String> ids);
  Future<void> replaceId(String oldId, String newId);
}
