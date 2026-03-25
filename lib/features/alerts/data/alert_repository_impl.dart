import 'package:kalig_onan_evac_system/features/alerts/data/alert_dto.dart';
import 'package:kalig_onan_evac_system/features/alerts/domain/alert.dart';
import 'package:kalig_onan_evac_system/features/alerts/domain/alert_repository.dart';
import 'package:kalig_onan_evac_system/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class AlertRepositoryImpl implements AlertRepository {
  const AlertRepositoryImpl(this._databaseService);

  final DatabaseService _databaseService;

  @override
  Future<List<Alert>> getByCenterId(String centerId) {
    return _databaseService.getAlertsByCenterId(centerId);
  }

  @override
  Future<List<Alert>> getAll() {
    return _databaseService.getAllAlerts();
  }

  @override
  Future<Alert?> getById(String id) {
    return _databaseService.getAlertById(id);
  }

  @override
  Future<List<Alert>> getUnread(String centerId) async {
    final alerts = await _databaseService.getAlertsByCenterId(centerId);
    return alerts.where((alert) => !alert.read).toList(growable: false);
  }

  @override
  Future<List<Alert>> getUrgent(String centerId) async {
    final alerts = await _databaseService.getAlertsByCenterId(centerId);
    return alerts
        .where((alert) => alert.severity == AlertSeverity.urgent)
        .toList(growable: false);
  }

  @override
  Future<List<Alert>> getUnsynced() {
    return _databaseService.getUnsyncedAlerts();
  }

  @override
  Future<void> insert(Alert alert) async {
    final db = await _databaseService.database;
    await db.insert(
      'alerts',
      alertToRow(alert.copyWith(synced: false)),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> markRead(String id) async {
    final db = await _databaseService.database;
    await db.update(
      'alerts',
      {'read': 1, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> upsertFromRemote(Alert alert) {
    return _databaseService.upsertAlertFromRemote(alert);
  }

  @override
  Future<void> markSynced(List<String> ids) {
    return _databaseService.markAlertsSynced(ids);
  }

  @override
  Future<void> replaceId(String oldId, String newId) {
    return _databaseService.replaceAlertId(oldId, newId);
  }
}

extension AlertDatabaseExtensions on DatabaseService {
  Future<List<Alert>> getAllAlerts() async {
    final db = await database;
    final maps = await db.query('alerts', orderBy: 'createdAt DESC');
    return [for (final map in maps) alertFromRow(map)];
  }

  Future<List<Alert>> getAlertsByCenterId(String centerId) async {
    final db = await database;
    final maps = await db.query(
      'alerts',
      where: 'evacuationCenterId = ?',
      whereArgs: [centerId],
      orderBy: 'createdAt DESC',
    );
    return [for (final map in maps) alertFromRow(map)];
  }

  Future<Alert?> getAlertById(String id) async {
    final db = await database;
    final maps = await db.query(
      'alerts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : alertFromRow(maps.first);
  }

  Future<void> upsertAlertFromRemote(Alert alert) async {
    final db = await database;
    await db.insert(
      'alerts',
      alertToRow(alert.copyWith(synced: true)),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceAlertId(String oldId, String newId) async {
    final db = await database;
    await db.update(
      'alerts',
      {'id': newId, 'synced': 0},
      where: 'id = ?',
      whereArgs: [oldId],
    );
  }

  Future<List<Alert>> getUnreadAlerts() async {
    final db = await database;
    final maps = await db.query(
      'alerts',
      where: 'read = 0',
      orderBy: 'createdAt DESC',
    );
    return [for (final map in maps) alertFromRow(map)];
  }

  Future<List<Alert>> getUnsyncedAlerts() async {
    final db = await database;
    final maps = await db.query(
      'alerts',
      where: 'synced = 0',
      orderBy: 'createdAt DESC',
    );
    return [for (final map in maps) alertFromRow(map)];
  }

  Future<void> markAlertsSynced(List<String> ids) async {
    if (ids.isEmpty) return;

    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final id in ids) {
        batch.update('alerts', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
      }
      await batch.commit(noResult: true);
    });
  }
}
