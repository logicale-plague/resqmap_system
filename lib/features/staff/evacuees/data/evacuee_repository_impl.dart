import 'package:kalig_onan_evac_system/features/staff/evacuees/application/register_evacuee.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/application/update_evacuee.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/data/evacuee_db_extension.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/domain/evacuee.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/domain/evacuee_repository.dart';

class EvacueeRepositoryImpl implements EvacueeRepository {
  final DatabaseService _databaseService;
  final RegisterEvacueeUseCase _registerEvacueeUseCase;
  final UpdateEvacueeUseCase _updateEvacueeUseCase;

  EvacueeRepositoryImpl(
    this._databaseService, {
    required RegisterEvacueeUseCase registerEvacueeUseCase,
    required UpdateEvacueeUseCase updateEvacueeUseCase,
  }) : _registerEvacueeUseCase = registerEvacueeUseCase,
       _updateEvacueeUseCase = updateEvacueeUseCase;

  @override
  Future<List<Evacuee>> getUnnamedByStation(String stationId) =>
      _databaseService.getUnnamedEvacueesByStation(stationId);

  @override
  Future<List<Evacuee>> getAll({bool includeInactive = false}) =>
      _databaseService.getAllEvacuees(includeInactive: includeInactive);

  @override
  Future<int> getCount() => _databaseService.getEvacueeCount();

  @override
  Future<int> getCountByStation(String stationId) =>
      _databaseService.getEvacueeCountByStation(stationId);

  @override
  Future<List<Evacuee>> getEvacueesByStation(String stationId) =>
      _databaseService.getEvacueesByStation(stationId);

  @override
  Future<Evacuee?> getById(String id) => _databaseService.getEvacueeById(id);

  @override
  Future<void> insert(Evacuee evacuee) =>
      _registerEvacueeUseCase.registerEvacuee(evacuee);

  @override
  Future<void> update(Evacuee evacuee) =>
      _updateEvacueeUseCase.updateEvacuee(evacuee);

  @override
  Future<void> upsertFromRemote(Evacuee evacuee) =>
      _databaseService.upsertEvacueeFromRemote(evacuee);

  @override
  Future<void> unassignEvacueesFromStation(String stationId) =>
      _databaseService.unassignEvacueesFromStation(stationId);

  @override
  Future<void> markSynced(List<String> ids) =>
      _databaseService.markEvacueesSynced(ids);

  @override
  Future<void> replaceId(String oldId, String newId) =>
      _databaseService.replaceEvacueeId(oldId, newId);
}
