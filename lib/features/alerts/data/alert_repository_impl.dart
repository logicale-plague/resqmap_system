import 'package:kalig_onan_evac_system/features/alerts/data/alert_dto.dart';
import 'package:kalig_onan_evac_system/features/alerts/domain/alert.dart';
import 'package:kalig_onan_evac_system/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

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
    final maps = await db.query('alerts', where: 'read = 0');
    return [for (final map in maps) alertFromRow(map)];
  }

  Future<List<Alert>> getUnsyncedAlerts() async {
    final db = await database;
    final maps = await db.query('alerts', where: 'synced = 0');
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
