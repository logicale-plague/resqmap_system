import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database_service.dart';
import 'id_service.dart';
import '../models/index.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();

  factory SyncService() {
    return _instance;
  }

  SyncService._internal();

  final _databaseService = DatabaseService();
  final _supabase = Supabase.instance.client;
  final _syncStatusController = StreamController<bool>.broadcast();
  DateTime? _lastSyncTime;
  bool _isShutDown = false;

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

    _isOnline = online;
    if (online) {
      unawaited(syncNow());
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

    try {
      await _normalizeLegacyIds();

      final unsyncedCenters = await _databaseService.getUnsyncedCenters();
      final unsyncedEvacuees = await _databaseService.getUnsyncedEvacuees();
      final unsyncedSupplies = await _databaseService.getUnsyncedSupplies();
      final unsyncedAlerts = await _databaseService.getUnsyncedAlerts();

      if (unsyncedCenters.isNotEmpty) {
        final payload = unsyncedCenters
            .map((center) => _centerToRemoteMap(center))
            .toList();
        await _supabase.from('evacuation_centers').upsert(payload);
        await _databaseService.markCentersSynced(
          unsyncedCenters.map((center) => center.id).toList(),
        );
      }

      if (unsyncedEvacuees.isNotEmpty) {
        final payload = unsyncedEvacuees
            .map((evacuee) => _evacueeToRemoteMap(evacuee))
            .toList();
        await _supabase.from('evacuees').upsert(payload);

        await _databaseService.markEvacueesSynced(
          unsyncedEvacuees.map((evacuee) => evacuee.id).toList(),
        );
      }

      if (unsyncedSupplies.isNotEmpty) {
        final payload = unsyncedSupplies
            .map((supply) => _supplyToRemoteMap(supply))
            .toList();
        await _supabase.from('supplies').upsert(payload);
        await _databaseService.markSuppliesSynced(
          unsyncedSupplies.map((supply) => supply.id).toList(),
        );
      }

      if (unsyncedAlerts.isNotEmpty) {
        final payload = unsyncedAlerts
            .map((alert) => _alertToRemoteMap(alert))
            .toList();
        await _supabase.from('alerts').upsert(payload);
        await _databaseService.markAlertsSynced(
          unsyncedAlerts.map((alert) => alert.id).toList(),
        );
      }

      await _pullAndMergeFromSupabase();

      _lastSyncTime = DateTime.now();

      debugPrint('Sync completed successfully with Supabase upload');
    } catch (e) {
      debugPrint('Sync failed: $e');
      rethrow;
    }
  }

  Future<void> _normalizeLegacyIds() async {
    final centers = await _databaseService.getAllCenters();
    for (final center in centers) {
      if (!_isUuid(center.id)) {
        await _databaseService.replaceCenterId(center.id, IdService.newId());
      }
    }

    final evacuees = await _databaseService.getAllEvacuees();
    for (final evacuee in evacuees) {
      if (!_isUuid(evacuee.id)) {
        await _databaseService.replaceEvacueeId(evacuee.id, IdService.newId());
      }
    }

    final supplies = await _databaseService.getAllSupplies();
    for (final supply in supplies) {
      if (!_isUuid(supply.id)) {
        await _databaseService.replaceSupplyId(supply.id, IdService.newId());
      }
    }

    final alerts = await _databaseService.getAllAlerts();
    for (final alert in alerts) {
      if (!_isUuid(alert.id)) {
        await _databaseService.replaceAlertId(alert.id, IdService.newId());
      }
    }
  }

  bool _isUuid(String value) => _uuidPattern.hasMatch(value);

  Future<void> _pullAndMergeFromSupabase() async {
    final centerRows = await _supabase.from('evacuation_centers').select();
    for (final row in centerRows) {
      await _mergeCenter(_asMap(row));
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

    final alertRows = await _supabase.from('alerts').select();
    for (final row in alertRows) {
      await _mergeAlert(_asMap(row));
    }
  }

  Future<void> _mergeCenter(Map<String, dynamic> row) async {
    final remote = EvacuationCenter(
      id: _readString(row, 'id'),
      name: _readString(row, 'name'),
      latitude: _readNum(row, 'latitude').toDouble(),
      longitude: _readNum(row, 'longitude').toDouble(),
      totalCapacity: _readNum(
        row,
        'totalcapacity',
        fallback: 'totalCapacity',
      ).toInt(),
      currentOccupancy: _readNum(
        row,
        'currentoccupancy',
        fallback: 'currentOccupancy',
      ).toInt(),
      status: CenterStatus.values[_readNum(row, 'status').toInt()],
      medicalAvailable: _asBool(
        _readAny(row, 'medicalavailable', fallback: 'medicalAvailable'),
      ),
      lastUpdated: DateTime.parse(
        _readString(row, 'lastupdated', fallback: 'lastUpdated'),
      ),
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
      ageGroup: AgeGroup
          .values[_readNum(row, 'agegroup', fallback: 'ageGroup').toInt()],
      medicalCondition:
          MedicalCondition.values[_readNum(
            row,
            'medicalcondition',
            fallback: 'medicalCondition',
          ).toInt()],
      registeredAt: DateTime.parse(
        _readString(row, 'registeredat', fallback: 'registeredAt'),
      ),
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

  Future<void> _mergeSupply(Map<String, dynamic> row) async {
    final remote = Supply(
      id: _readString(row, 'id'),
      name: _readString(row, 'name'),
      currentStock: _readNum(
        row,
        'currentstock',
        fallback: 'currentStock',
      ).toInt(),
      usageRatePerDay: _readNum(
        row,
        'usagerateperday',
        fallback: 'usageRatePerDay',
      ).toInt(),
      lastRestocked: DateTime.parse(
        _readString(row, 'lastrestocked', fallback: 'lastRestocked'),
      ),
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

  Future<void> _mergeAlert(Map<String, dynamic> row) async {
    final remote = Alert(
      id: _readString(row, 'id'),
      message: _readString(row, 'message'),
      severity: AlertSeverity.values[_readNum(row, 'severity').toInt()],
      createdAt: DateTime.parse(
        _readString(row, 'createdat', fallback: 'createdAt'),
      ),
      read: _asBool(_readAny(row, 'read')),
      synced: true,
    );

    final local = await _databaseService.getAlertById(remote.id);
    if (local == null) {
      await _databaseService.upsertAlertFromRemote(remote);
      return;
    }

    if (!local.synced && !remote.createdAt.isAfter(local.createdAt)) {
      return;
    }

    await _databaseService.upsertAlertFromRemote(remote);
  }

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
      'latitude': center.latitude,
      'longitude': center.longitude,
      'totalcapacity': center.totalCapacity,
      'currentoccupancy': center.currentOccupancy,
      'status': center.status.index,
      'medicalavailable': center.medicalAvailable ? 1 : 0,
      'lastupdated': center.lastUpdated.toIso8601String(),
      'synced': center.synced ? 1 : 0,
    };
  }

  Map<String, dynamic> _evacueeToRemoteMap(Evacuee evacuee) {
    return {
      'id': evacuee.id,
      'name': evacuee.name,
      'agegroup': evacuee.ageGroup.index,
      'medicalcondition': evacuee.medicalCondition.index,
      'registeredat': evacuee.registeredAt.toIso8601String(),
      'synced': evacuee.synced ? 1 : 0,
    };
  }

  Map<String, dynamic> _supplyToRemoteMap(Supply supply) {
    return {
      'id': supply.id,
      'name': supply.name,
      'currentstock': supply.currentStock,
      'usagerateperday': supply.usageRatePerDay,
      'lastrestocked': supply.lastRestocked.toIso8601String(),
      'synced': supply.synced ? 1 : 0,
    };
  }

  Map<String, dynamic> _alertToRemoteMap(Alert alert) {
    return {
      'id': alert.id,
      'message': alert.message,
      'severity': alert.severity.index,
      'createdat': alert.createdAt.toIso8601String(),
      'read': alert.read ? 1 : 0,
    };
  }

  dynamic _readAny(Map<String, dynamic> row, String key, {String? fallback}) {
    if (row.containsKey(key)) {
      return row[key];
    }
    if (fallback != null && row.containsKey(fallback)) {
      return row[fallback];
    }
    throw StateError('Missing key "$key" in Supabase row.');
  }

  String _readString(Map<String, dynamic> row, String key, {String? fallback}) {
    return _readAny(row, key, fallback: fallback).toString();
  }

  num _readNum(Map<String, dynamic> row, String key, {String? fallback}) {
    final value = _readAny(row, key, fallback: fallback);
    if (value is num) return value;
    return num.parse(value.toString());
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
          'evacuees': 0,
          'supplies': 0,
          'alerts': 0,
        },
      };
    }

    final unsyncedCenters = await _databaseService.getUnsyncedCenters();
    final unsyncedEvacuees = await _databaseService.getUnsyncedEvacuees();
    final unsyncedSupplies = await _databaseService.getUnsyncedSupplies();
    final unsyncedAlerts = await _databaseService.getUnsyncedAlerts();

    final pendingUpdates =
        unsyncedCenters.length +
        unsyncedEvacuees.length +
        unsyncedSupplies.length +
        unsyncedAlerts.length;

    return {
      'isOnline': _isOnline,
      'lastSyncTime': _lastSyncTime,
      'pendingUpdates': pendingUpdates,
      'pendingByEntity': {
        'centers': unsyncedCenters.length,
        'evacuees': unsyncedEvacuees.length,
        'supplies': unsyncedSupplies.length,
        'alerts': unsyncedAlerts.length,
      },
    };
  }

  Future<void> shutdown() async {
    if (_isShutDown) return;

    _isShutDown = true;
    _isOnline = false;

    if (!_syncStatusController.isClosed) {
      await _syncStatusController.close();
    }
  }

  @Deprecated('Use shutdown() for app-level lifecycle teardown.')
  void dispose() {
    unawaited(shutdown());
  }
}
