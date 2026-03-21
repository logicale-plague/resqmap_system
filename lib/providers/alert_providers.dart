import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../models/alert.dart';
import '../services/database_service.dart';
import 'database_provider.dart';

final allAlertsProvider = FutureProvider<List<Alert>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAllAlerts();
});

final unsyncedAlertsProvider = FutureProvider<List<Alert>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getUnsyncedAlerts();
});

final alertProvider = FutureProvider.family<Alert?, String>((ref, id) async {
  final db = ref.watch(databaseServiceProvider);
  final alerts = await db.getAllAlerts();
  try {
    return alerts.firstWhere((a) => a.id == id);
  } catch (e) {
    return null;
  }
});

final unreadAlertsProvider = FutureProvider<List<Alert>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final alerts = await db.getAllAlerts();
  return alerts.where((a) => !a.read).toList();
});

final urgentAlertsProvider = FutureProvider<List<Alert>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final alerts = await db.getAllAlerts();
  return alerts.where((a) => a.severity == AlertSeverity.urgent).toList();
});

extension AlertDatabaseExtensions on DatabaseService {
  Future<void> insertAlert(Alert alert) async {
    final db = await database;
    await db.insert(
      'alerts',
      alert.copyWith(synced: false).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Alert>> getAllAlerts() async {
    final db = await database;
    final maps = await db.query('alerts', orderBy: 'createdAt DESC');
    return [for (final map in maps) Alert.fromMap(map)];
  }

  Future<Alert?> getAlertById(String id) async {
    final db = await database;
    final maps = await db.query(
      'alerts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : Alert.fromMap(maps.first);
  }

  Future<void> upsertAlertFromRemote(Alert alert) async {
    final db = await database;
    await db.insert(
      'alerts',
      alert.copyWith(synced: true).toMap(),
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
    return [for (final map in maps) Alert.fromMap(map)];
  }

  Future<void> markAlertAsRead(String alertId) async {
    final db = await database;
    await db.update(
      'alerts',
      {'read': 1, 'synced': 0},
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  Future<List<Alert>> getUnsyncedAlerts() async {
    final db = await database;
    final maps = await db.query('alerts', where: 'synced = 0');
    return [for (final map in maps) Alert.fromMap(map)];
  }

  Future<void> markAlertsSynced(List<String> ids) async {
    final db = await database;
    for (final id in ids) {
      await db.update(
        'alerts',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
