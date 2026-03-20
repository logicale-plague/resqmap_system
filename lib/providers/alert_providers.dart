import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert.dart';
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
