import 'package:flutter/foundation.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/application/register_center.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/application/update_center.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/data/evacuation_center_db_extension.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/data/evacuation_center_dto.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EvacuationCenterRepositoryImpl implements EvacuationCenterRepository {
  final DatabaseService _databaseService;
  final SupabaseClient _supabaseClient;
  final RegisterCenterUseCase _registerCenter;
  final UpdateCenterUseCase _updateCenterCapacity;

  EvacuationCenterRepositoryImpl(
    this._databaseService, {
    required SupabaseClient supabaseClient,
    required RegisterCenterUseCase registerCenter,
    required UpdateCenterUseCase updateCenterCapacity,
  }) : _supabaseClient = supabaseClient,
       _registerCenter = registerCenter,
       _updateCenterCapacity = updateCenterCapacity;

  @override
  Future<EvacuationCenter?> getCurrent() => _databaseService.getCurrentCenter();

  @override
  Future<List<EvacuationCenter>> getAll() => _databaseService.getAllCenters();

  @override
  Future<List<EvacuationCenter>> getAllViaPostal() =>
      _databaseService.getAllCentersViaPostal();

  @override
  Future<List<EvacuationCenter>> getUnsynced() =>
      _databaseService.getUnsyncedCenters();

  @override
  Future<EvacuationCenter?> getById(String id) =>
      _databaseService.getCenterById(id);

  @override
  Future<List<EvacuationCenter>> getByCommandCenterId(
    String commandCenterId,
  ) async {
    final localCenters = await _getByCommandCenterIdFromLocal(commandCenterId);
    if (localCenters.isNotEmpty) {
      return localCenters;
    }

    List<dynamic> rows;
    try {
      rows = await _supabaseClient
          .from('evacuation_centers')
          .select()
          .eq('command_center_id', commandCenterId);
    } catch (error, stackTrace) {
      // Log the error and stack trace for debugging
      if (kDebugMode) {
        print('Error fetching centers from Supabase: $error');
        print('Stack trace: $stackTrace');
      }
      return localCenters;
    }
    return [
      for (final row in rows)
        _centerFromRemoteMap(
          Map<String, dynamic>.from(row as Map),
          commandCenterId,
        ),
    ];
  }

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
  Future<void> update(EvacuationCenter center) async {
    final updated = await _updateCenterCapacity.updateCenter(center);
    if (!updated) {
      throw StateError('Failed to update center with id=${center.id}.');
    }
  }

  Future<List<EvacuationCenter>> _getByCommandCenterIdFromLocal(
    String commandCenterId,
  ) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'evacuation_centers',
      where: 'commandCenterId = ?',
      whereArgs: [commandCenterId],
    );
    return [for (final map in maps) centerFromMap(map)];
  }

  EvacuationCenter _centerFromRemoteMap(
    Map<String, dynamic> map,
    String commandCenterId,
  ) {
    return centerFromMap({
      'id': map['id'],
      'name': map['name'],
      'commandCenterId': map['command_center_id'] ?? commandCenterId,
      'latitude': map['latitude'],
      'longitude': map['longitude'],
      'totalCapacity': map['total_capacity'],
      'currentOccupancy': map['current_occupancy'],
      'status': map['status'],
      'medicalAvailable': _asBool(map['medical_available']) ? 1 : 0,
      'lastUpdated': map['last_updated'],
      'synced': _asBool(map['synced']) ? 1 : 0,
    });
  }

  bool _asBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value.toString().toLowerCase() == 'true';
  }
}
