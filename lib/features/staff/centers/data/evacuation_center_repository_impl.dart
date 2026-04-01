import 'package:kalig_onan_evac_system/features/staff/centers/application/register_center.dart';
import 'package:kalig_onan_evac_system/features/staff/centers/application/update_center.dart';
import 'package:kalig_onan_evac_system/features/staff/centers/data/evacuation_center_db_extension.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/index.dart';
import 'package:kalig_onan_evac_system/features/staff/centers/domain/evacuation_center_repository.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';

class EvacuationCenterRepositoryImpl implements EvacuationCenterRepository {
  final DatabaseService _databaseService;
  final RegisterCenterUseCase _registerCenter;
  final UpdateCenterUseCase _updateCenterCapacity;

  EvacuationCenterRepositoryImpl(
    this._databaseService, {
    required RegisterCenterUseCase registerCenter,
    required UpdateCenterUseCase updateCenterCapacity,
  }) : _registerCenter = registerCenter,
       _updateCenterCapacity = updateCenterCapacity;

  @override
  Future<EvacuationCenter?> getCurrent() => _databaseService.getCurrentCenter();

  @override
  Future<List<EvacuationCenter>> getAll() => _databaseService.getAllCenters();

  @override
  Future<EvacuationCenter?> getById(String id) =>
      _databaseService.getCenterById(id);

  @override
  Future<String> getCurrentCommandCenterId() =>
      _databaseService.getCurrentCommandCenterId();

  @override
  Future<void> insert(EvacuationCenter center) =>
      _registerCenter.registerCenter(center);

  @override
  Future<void> upsertFromRemote(EvacuationCenter center) =>
      _databaseService.upsertCenterFromRemote(center);

  @override
  Future<void> markSynced(List<String> ids) =>
      _databaseService.markCentersSynced(ids);

  @override
  Future<void> replaceId(String oldId, String newId) =>
      _databaseService.replaceCenterId(oldId, newId);

  @override
  Future<void> update(EvacuationCenter center) =>
      _updateCenterCapacity.updateCenter(center);
}
