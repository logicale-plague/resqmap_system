import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/indices/db_extensions_index.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/supabase_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/core/utils/id_service.dart';
import 'package:kalig_onan_evac_system/core/indices/models_index.dart';
import 'package:kalig_onan_evac_system/features/authentication/data/user_persistence_extensions.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final supabase = ref.watch(supabaseProvider);
  final service = SyncService(
    databaseService: databaseService,
    supabase: supabase,
  );
  ref.onDispose(() {
    unawaited(service.shutdown());
  });
  return service;
});

class SyncService {
  SyncService({
    required DatabaseService databaseService,
    required SupabaseClient supabase,
  }) : _databaseService = databaseService,
       _supabase = supabase;

  final DatabaseService _databaseService;
  final SupabaseClient _supabase;
  final _syncStatusController = StreamController<bool>.broadcast();
  DateTime? _lastSyncTime;
  bool _isShutDown = false;
  // bool _isSyncInProgress = false;
  Future<void>? _activeSyncFuture;
  Timer? _retryTimer;
  int _retryAttempts = 0;

  static const int _maxRetryAttempts = 5;
  static const Duration _baseRetryDelay = Duration(seconds: 3);
  static const Duration _maxRetryDelay = Duration(minutes: 2);

  Stream<bool> get syncStatusStream => _syncStatusController.stream;

  bool _isOnline = false;

  bool get isOnline => _isOnline;
  bool get isShutDown => _isShutDown;
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  // In a real app, this would check actual network connectivity
  void setOnlineStatus(bool online) {
    if (_isShutDown) {
      debugPrint('SyncService is shut down; ignoring setOnlineStatus call.');
      return;
    }

    final wasOnline = _isOnline;
    _isOnline = online;
    if (!online) {
      _cancelRetryTimer();
      _retryAttempts = 0;
    }
    if (online && !wasOnline) {
      _retryAttempts = 0;
      _runSyncInBackground();
    }
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(online);
    }
  }

  Future<void> syncNow() async {
    if (_isShutDown) {
      debugPrint('SyncService is shut down; skipping sync.');
      return;
    }

    if (!_isOnline) {
      debugPrint('Device is offline; skipping sync.');
      return;
    }

    final activeSyncFuture = _activeSyncFuture;
    if (activeSyncFuture != null) {
      debugPrint('Sync already in progress; joining active sync request.');
      return activeSyncFuture;
    }

    late final Future<void> trackedSyncFuture;
    trackedSyncFuture = _performSync().whenComplete(() {
      if (identical(_activeSyncFuture, trackedSyncFuture)) {
        _activeSyncFuture = null;
      }
    });
    _activeSyncFuture = trackedSyncFuture;
    return trackedSyncFuture;
  }

  Future<void> _performSync() async {
    // _isSyncInProgress = true;
    var hadEntityFailures = false;
    var hadStationFailures = false;

    try {
      await _normalizeLegacyIds();

      final unsyncedCenters = await _databaseService.getUnsyncedCenters();
      final unsyncedStations = await _databaseService.getUnsyncedStations();
      final unsyncedEvacuees = await _databaseService.getUnsyncedEvacuees();
      final unsyncedSupplies = await _databaseService.getUnsyncedSupplies();
      // final unsyncedAlerts = await _databaseService.getUnsyncedAlerts();

      if (unsyncedCenters.isNotEmpty) {
        final syncedCenterIds = <String>[];
        for (final center in unsyncedCenters) {
          try {
            await _supabase.from('evacuation_centers').upsert([
              _centerToRemoteMap(center),
            ]);
            syncedCenterIds.add(center.id);
          } catch (e) {
            hadEntityFailures = true;
            debugPrint('Center sync failed for id=${center.id}: $e');
          }
        }

        await _databaseService.markCentersSynced(syncedCenterIds);
      }

      if (unsyncedStations.isNotEmpty) {
        final syncedStationIds = <String>[];
        for (final station in unsyncedStations) {
          try {
            await _supabase.from('stations').upsert([
              _stationToRemoteMap(station),
            ]);
            syncedStationIds.add(station.id);
          } catch (e) {
            hadEntityFailures = true;
            hadStationFailures = true;
            debugPrint('Station sync failed for id=${station.id}: $e');
          }
        }

        await _databaseService.markStationsSynced(syncedStationIds);
      }

      if (unsyncedEvacuees.isNotEmpty) {
        final syncedEvacueeIds = <String>[];
        for (final evacuee in unsyncedEvacuees) {
          try {
            await _supabase.from('evacuees').upsert([
              _evacueeToRemoteMap(evacuee),
            ]);
            syncedEvacueeIds.add(evacuee.id);
          } catch (e) {
            hadEntityFailures = true;
            debugPrint('Evacuee sync failed for id=${evacuee.id}: $e');
          }
        }

        await _databaseService.markEvacueesSynced(syncedEvacueeIds);
      }

      if (unsyncedSupplies.isNotEmpty) {
        final syncedSupplyIds = <String>[];
        for (final supply in unsyncedSupplies) {
          try {
            await _uploadSupplies([_supplyToRemoteMap(supply)]);
            syncedSupplyIds.add(supply.id);
          } catch (e) {
            hadEntityFailures = true;
            debugPrint('Supply sync failed for id=${supply.id}: $e');
          }
        }

        await _databaseService.markSuppliesSynced(syncedSupplyIds);
      }

      await _pullAndMergeFromSupabase(skipStations: hadStationFailures);

      if (hadEntityFailures) {
        _scheduleRetry();
        throw StateError(
          'Sync completed with partial failures. Check logs for failing records.',
        );
      }

      _lastSyncTime = DateTime.now();
      _retryAttempts = 0;
      _cancelRetryTimer();

      debugPrint('Sync completed successfully with Supabase upload');
    } catch (e) {
      debugPrint('Sync failed: $e');
      _scheduleRetry();
      rethrow;
    } finally {
      // _isSyncInProgress = false;
    }
  }

  void _runSyncInBackground() {
    unawaited(
      syncNow().catchError((Object error, StackTrace stackTrace) {
        debugPrint('Background sync attempt failed: $error');
      }),
    );
  }

  void _scheduleRetry() {
    if (_isShutDown || !_isOnline) {
      return;
    }
    if (_retryTimer?.isActive ?? false) {
      return;
    }
    if (_retryAttempts >= _maxRetryAttempts) {
      debugPrint('Sync retry limit reached ($_maxRetryAttempts attempts).');
      return;
    }

    _retryAttempts += 1;
    final delay = _retryDelayForAttempt(_retryAttempts);
    debugPrint(
      'Scheduling sync retry $_retryAttempts/$_maxRetryAttempts in ${delay.inSeconds}s.',
    );

    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (_isShutDown || !_isOnline) {
        return;
      }
      _runSyncInBackground();
    });
  }

  Duration _retryDelayForAttempt(int attempt) {
    final multiplier = 1 << (attempt - 1);
    final seconds = _baseRetryDelay.inSeconds * multiplier;
    final clampedSeconds = seconds > _maxRetryDelay.inSeconds
        ? _maxRetryDelay.inSeconds
        : seconds;
    return Duration(seconds: clampedSeconds);
  }

  void _cancelRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Future<void> _normalizeLegacyIds() async {
    final centers = await _databaseService.getAllCenters();
    for (final center in centers) {
      if (!_isUuid(center.id)) {
        await _databaseService.replaceCenterId(center.id, IdService.newId());
      }
    }

    final evacuees = await _databaseService.getAllEvacuees(
      includeInactive: true,
    );
    for (final evacuee in evacuees) {
      if (!_isUuid(evacuee.id)) {
        await _databaseService.replaceEvacueeId(evacuee.id, IdService.newId());
      }
    }

    final stations = await _databaseService.getAllStations();
    for (final station in stations) {
      if (!_isUuid(station.id)) {
        await _databaseService.replaceStationId(station.id, IdService.newId());
      }
    }

    final supplies = await _databaseService.getAllSupplies();
    for (final supply in supplies) {
      if (!_isUuid(supply.id)) {
        await _databaseService.replaceSupplyId(supply.id, IdService.newId());
      }
    }
  }

  bool _isUuid(String value) => _uuidPattern.hasMatch(value);

  Future<void> _pullAndMergeFromSupabase({bool skipStations = false}) async {
    await _refreshCurrentUserCommandCenterAccess();
    await _refreshCurrentUserEvacCenterAccess();

    final centerRows = await _supabase.from('evacuation_centers').select();
    for (final row in centerRows) {
      await _mergeCenter(_asMap(row));
    }

    if (!skipStations) {
      final stationRows = await _supabase.from('stations').select();
      for (final row in stationRows) {
        await _mergeStation(_asMap(row));
      }
    }

    final evacueeRows = await _supabase.from('evacuees').select();
    bool evacueeChanged = false;
    for (final row in evacueeRows) {
      final changed = await _mergeEvacuee(_asMap(row));
      if (changed) {
        evacueeChanged = true;
      }
    }
    if (evacueeChanged) {
      await _databaseService.refreshCurrentCenterOccupancy();
    }

    final supplyRows = await _supabase.from('supplies').select();
    for (final row in supplyRows) {
      await _mergeSupply(_asMap(row));
    }

    // final alertRows = await _supabase.from('alerts').select();
    // for (final row in alertRows) {
    //   await _mergeAlert(_asMap(row));
    // }
  }

  Future<void> _refreshCurrentUserCommandCenterAccess() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      final rawRows = await _supabase
          .from('user_cmd_centers')
          .select()
          .eq('user_id', userId);
      final accessRows = [
        for (final row in rawRows) Map<String, dynamic>.from(row as Map),
      ];
      await _databaseService.replaceUserCommandCenterAccess(userId, accessRows);
    } catch (e) {
      debugPrint('Failed to pull user_cmd_centers for user=$userId: $e');
    }
  }

  Future<void> _refreshCurrentUserEvacCenterAccess() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      final rawRows = await _supabase
          .from('user_evac_centers')
          .select()
          .eq('user_id', userId);
      final accessRows = [
        for (final row in rawRows) Map<String, dynamic>.from(row as Map),
      ];
      await _databaseService.replaceUserEvacCenterAccess(userId, accessRows);
    } catch (e) {
      debugPrint('Failed to pull user_evac_centers for user=$userId: $e');
    }
  }

  Future<void> _mergeCenter(Map<String, dynamic> row) async {
    final remote = EvacuationCenter(
      id: _readString(row, 'id'),
      name: _readString(row, 'name'),
      commandCenterId:
          _readAnyOrNull(row, 'command_center_id')?.toString() ??
          'default-command-center',
      latitude: _readNum(row, 'latitude').toDouble(),
      longitude: _readNum(row, 'longitude').toDouble(),
      fullAddress: _readString(row, 'full_address'),
      postalCode: _readString(row, 'postal_code'),
      totalCapacity: _readNum(row, 'total_capacity').toInt(),
      currentOccupancy: _readNum(row, 'current_occupancy').toInt(),
      status: CenterStatus.values[_readNum(row, 'status').toInt()],
      medicalAvailable: _asBool(_readAny(row, 'medical_available')),
      lastUpdated: DateTime.parse(_readString(row, 'last_updated')),
      synced: true,
    );

    final local = await _databaseService.getCenterById(remote.id);
    if (local == null) {
      await _databaseService.upsertCenterFromRemote(remote);
      return;
    }

    if (!local.synced && !remote.lastUpdated.isAfter(local.lastUpdated)) {
      return;
    }

    await _databaseService.upsertCenterFromRemote(remote);
  }

  Future<bool> _mergeEvacuee(Map<String, dynamic> row) async {
    final remote = Evacuee(
      id: _readString(row, 'id'),
      name: _readAny(row, 'name') as String?,
      stationId: _readAnyOrNull(row, 'station_id') as String?,
      ageGroup: AgeGroup.values[_readNum(row, 'age_group').toInt()],
      medicalCondition:
          MedicalCondition.values[_readNum(row, 'medical_condition').toInt()],
      registeredAt: DateTime.parse(_readString(row, 'registered_at')),
      active: _asBool(_readAnyOrNull(row, 'active') ?? 1),
      synced: true,
    );

    final local = await _databaseService.getEvacueeById(remote.id);
    if (local == null) {
      await _databaseService.upsertEvacueeFromRemote(remote);
      return true;
    }

    if (!local.synced && !remote.registeredAt.isAfter(local.registeredAt)) {
      return false;
    }

    await _databaseService.upsertEvacueeFromRemote(remote);
    return true;
  }

  Future<void> _mergeStation(Map<String, dynamic> row) async {
    final remote = Station(
      id: _readString(row, 'id'),
      name: _readString(row, 'name'),
      evacuationCenterId: _readString(row, 'evacuation_center_id'),
      capacity: _readNum(row, 'capacity').toInt(),
      allowedAgeGroup: _enumOrNull(
        AgeGroup.values,
        _readAnyOrNull(row, 'allowed_age_group'),
      ),
      allowedMedicalCondition: _enumOrNull(
        MedicalCondition.values,
        _readAnyOrNull(row, 'allowed_medical_condition'),
      ),
      synced: true,
    );

    await _databaseService.upsertStationFromRemote(remote);
  }

  Future<void> _mergeSupply(Map<String, dynamic> row) async {
    final fallbackCenterId = await _currentCenterIdOrDefault();
    final remote = Supply(
      id: _readString(row, 'id'),
      evacuationCenterId:
          _readAnyOrNull(row, 'evacuation_center_id')?.toString() ??
          fallbackCenterId,
      name: _readString(row, 'name'),
      currentStock: _readNum(row, 'current_stock').toInt(),
      usageRatePerDay: _readNum(row, 'usage_rate_per_day').toInt(),
      lastRestocked: DateTime.parse(_readString(row, 'last_restocked')),
      synced: true,
    );

    final local = await _databaseService.getSupplyById(remote.id);
    if (local == null) {
      await _databaseService.upsertSupplyFromRemote(remote);
      return;
    }

    if (!local.synced && !remote.lastRestocked.isAfter(local.lastRestocked)) {
      return;
    }

    await _databaseService.upsertSupplyFromRemote(remote);
  }

  // Future<void> _mergeAlert(Map<String, dynamic> row) async {
  //   final fallbackCenterId = await _currentCenterIdOrDefault();
  //   final remote = Alert(
  //     id: _readString(row, 'id'),
  //     evacuationCenterId:
  //         _readAnyOrNull(row, 'evacuation_center_id')?.toString() ??
  //         fallbackCenterId,
  //     message: _readString(row, 'message'),
  //     severity: AlertSeverity.values[_readNum(row, 'severity').toInt()],
  //     createdAt: DateTime.parse(_readString(row, 'created_at')),
  //     read: _asBool(_readAny(row, 'read')),
  //     synced: true,
  //   );

  //   final local = await _databaseService.getAlertById(remote.id);
  //   if (local == null) {
  //     await _databaseService.upsertAlertFromRemote(remote);
  //     return;
  //   }

  //   if (!local.synced && !remote.createdAt.isAfter(local.createdAt)) {
  //     return;
  //   }

  //   await _databaseService.upsertAlertFromRemote(remote);
  // }

  Map<String, dynamic> _asMap(dynamic row) {
    if (row is Map<String, dynamic>) {
      return row;
    }
    return Map<String, dynamic>.from(row as Map);
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  Map<String, dynamic> _centerToRemoteMap(EvacuationCenter center) {
    return {
      'id': center.id,
      'name': center.name,
      'command_center_id': center.commandCenterId,
      'latitude': center.latitude,
      'longitude': center.longitude,
      'full_address': center.fullAddress,
      'postal_code': center.postalCode,
      'total_capacity': center.totalCapacity,
      'current_occupancy': center.currentOccupancy,
      'status': center.status.index,
      'medical_available': center.medicalAvailable ? 1 : 0,
      'last_updated': center.lastUpdated.toIso8601String(),
      'synced': center.synced ? 1 : 0,
    };
  }

  Map<String, dynamic> _evacueeToRemoteMap(Evacuee evacuee) {
    return {
      'id': evacuee.id,
      'name': evacuee.name?.trim() ?? '',
      'station_id': evacuee.stationId,
      'age_group': evacuee.ageGroup.index,
      'medical_condition': evacuee.medicalCondition.index,
      'registered_at': evacuee.registeredAt.toIso8601String(),
      'active': evacuee.active ? 1 : 0,
    };
  }

  Map<String, dynamic> _supplyToRemoteMap(Supply supply) {
    return {
      'id': supply.id,
      'evacuation_center_id': supply.evacuationCenterId,
      'name': supply.name,
      'current_stock': supply.currentStock,
      'usage_rate_per_day': supply.usageRatePerDay,
      'last_restocked': supply.lastRestocked.toIso8601String(),
    };
  }

  Map<String, dynamic> _stationToRemoteMap(Station station) {
    return {
      'id': station.id,
      'name': station.name,
      'evacuation_center_id': station.evacuationCenterId,
      'capacity': station.capacity,
      'allowed_age_group': station.allowedAgeGroup?.index,
      'allowed_medical_condition': station.allowedMedicalCondition?.index,
    };
  }

  // Map<String, dynamic> _alertToRemoteMap(Alert alert) {
  //   return {
  //     'id': alert.id,
  //     'evacuation_center_id': alert.evacuationCenterId,
  //     'message': alert.message,
  //     'severity': alert.severity.index,
  //     'created_at': alert.createdAt.toIso8601String(),
  //     'read': alert.read ? 1 : 0,
  //   };
  // }

  dynamic _readAny(Map<String, dynamic> row, String key, {String? fallback}) {
    if (row.containsKey(key)) {
      return row[key];
    }
    if (fallback != null && row.containsKey(fallback)) {
      return row[fallback];
    }
    throw StateError('Missing key "$key" in Supabase row.');
  }

  dynamic _readAnyOrNull(
    Map<String, dynamic> row,
    String key, {
    String? fallback,
  }) {
    if (row.containsKey(key)) {
      return row[key];
    }
    if (fallback != null && row.containsKey(fallback)) {
      return row[fallback];
    }
    return null;
  }

  String _readString(Map<String, dynamic> row, String key, {String? fallback}) {
    return _readAny(row, key, fallback: fallback).toString();
  }

  num _readNum(Map<String, dynamic> row, String key, {String? fallback}) {
    final value = _readAny(row, key, fallback: fallback);
    if (value is num) return value;
    return num.parse(value.toString());
  }

  T? _enumOrNull<T>(List<T> values, dynamic rawValue) {
    if (rawValue == null) return null;
    if (rawValue is String) {
      for (final value in values) {
        if (value is Enum && value.name == rawValue) {
          return value;
        }
      }
    }
    final index = rawValue is num
        ? rawValue.toInt()
        : int.tryParse(rawValue.toString());
    if (index == null) return null;
    if (index < 0 || index >= values.length) return null;
    return values[index];
  }

  Future<void> _uploadSupplies(List<Map<String, dynamic>> payload) async {
    await _supabase.from('supplies').upsert(payload);
  }

  // Future<void> _uploadCenters(List<Map<String, dynamic>> payload) async {
  //   await _supabase.from('evacuation_centers').upsert(payload);
  // }

  Future<String> _currentCenterIdOrDefault() async {
    final center = await _databaseService.getCurrentCenter();
    return center?.id ?? 'default-center';
  }

  /// Get sync status for display
  Future<Map<String, dynamic>> getSyncStatus() async {
    if (_isShutDown) {
      return {
        'isOnline': false,
        'lastSyncTime': _lastSyncTime,
        'pendingUpdates': 0,
        'pendingByEntity': {
          'centers': 0,
          'stations': 0,
          'evacuees': 0,
          'supplies': 0,
          'alerts': 0,
        },
      };
    }

    final unsyncedCenters = await _databaseService.getUnsyncedCenters();
    final unsyncedStations = await _databaseService.getUnsyncedStations();
    final unsyncedEvacuees = await _databaseService.getUnsyncedEvacuees();
    final unsyncedSupplies = await _databaseService.getUnsyncedSupplies();
    // final unsyncedAlerts = await _databaseService.getUnsyncedAlerts();

    final pendingUpdates =
        unsyncedCenters.length +
        unsyncedStations.length +
        unsyncedEvacuees.length +
        unsyncedSupplies.length;
    // unsyncedAlerts.length;

    return {
      'isOnline': _isOnline,
      'lastSyncTime': _lastSyncTime,
      'pendingUpdates': pendingUpdates,
      'pendingByEntity': {
        'centers': unsyncedCenters.length,
        'stations': unsyncedStations.length,
        'evacuees': unsyncedEvacuees.length,
        'supplies': unsyncedSupplies.length,
        // 'alerts': unsyncedAlerts.length,
      },
    };
  }

  /// Push a single evacuation center directly to Supabase
  /// Throws an exception if offline or if the push fails
  Future<void> pushCenterToSupabase(EvacuationCenter center) async {
    if (!_isOnline) {
      throw Exception('Cannot push center: Device is offline');
    }

    if (_isShutDown) {
      throw Exception('SyncService is shut down');
    }

    final payload = _centerToRemoteMap(center);
    await _supabase.from('evacuation_centers').upsert([payload]);
  }

  Future<void> shutdown() async {
    if (_isShutDown) return;

    _isShutDown = true;
    _isOnline = false;
    _cancelRetryTimer();

    if (!_syncStatusController.isClosed) {
      await _syncStatusController.close();
    }
  }

  @Deprecated('Use shutdown() for app-level lifecycle teardown.')
  void dispose() {
    unawaited(shutdown());
  }
}
