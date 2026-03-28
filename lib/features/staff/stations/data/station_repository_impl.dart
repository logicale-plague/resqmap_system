import 'package:kalig_onan_evac_system/features/staff/evacuees/domain/evacuee.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/application/register_station.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/application/update_station.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/data/station_db_extension.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/domain/station.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/domain/station_repository.dart';

class StationRepositoryImpl implements StationRepository {
  final DatabaseService _databaseService;
  final RegisterStationUseCase _registerStationService;
  final UpdateStationUseCase _updateStationService;

  StationRepositoryImpl(
    this._databaseService, {
    required RegisterStationUseCase registerStationService,
    required UpdateStationUseCase updateStationService,
  }) : _registerStationService = registerStationService,
       _updateStationService = updateStationService;

  @override
  Future<List<Station>> getByCenter(String centerId) =>
      _databaseService.getStationsForCenter(centerId);

  @override
  Future<List<Station>> getEligible(
    String centerId,
    AgeGroup ageGroup,
    MedicalCondition medicalCondition,
  ) => _databaseService.getEligibleStations(
    centerId: centerId,
    ageGroup: ageGroup,
    medicalCondition: medicalCondition,
  );

  @override
  Future<Station?> getById(String stationId) =>
      _databaseService.getStationById(stationId);

  @override
  Future<List<Station>> getAll() => _databaseService.getAllStations();

  @override
  Future<void> insert(Station station) =>
      _registerStationService.registerStation(station);

  @override
  Future<void> update(Station station) =>
      _updateStationService.updateStation(station);

  @override
  Future<void> delete(Station station) =>
      _updateStationService.updateStation(station.copyWith(active: false));

  @override
  Future<void> upsertFromRemote(Station station) =>
      _databaseService.upsertStationFromRemote(station);

  @override
  Future<void> markSynced(List<String> ids) =>
      _databaseService.markStationsSynced(ids);

  @override
  Future<void> replaceId(String oldId, String newId) =>
      _databaseService.replaceStationId(oldId, newId);
}
