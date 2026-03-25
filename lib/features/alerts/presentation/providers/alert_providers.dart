import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/alerts/data/alert_repository_impl.dart';

import 'package:kalig_onan_evac_system/features/alerts/domain/alert.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/features/centers/presentation/providers/evacuation_center_providers.dart';

final allAlertsProvider = FutureProvider<List<Alert>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final center = await ref.watch(currentCenterProvider.future);
  if (center == null) return [];
  return db.getAlertsByCenterId(center.id);
});

final unsyncedAlertsProvider = FutureProvider<List<Alert>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getUnsyncedAlerts();
});

final alertProvider = FutureProvider.family<Alert?, String>((ref, id) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAlertById(id);
});

final unreadAlertsProvider = FutureProvider<List<Alert>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final center = await ref.watch(currentCenterProvider.future);
  if (center == null) return [];
  final alerts = await db.getAlertsByCenterId(center.id);
  return alerts.where((a) => !a.read).toList();
});

final urgentAlertsProvider = FutureProvider<List<Alert>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final center = await ref.watch(currentCenterProvider.future);
  if (center == null) return [];
  final alerts = await db.getAlertsByCenterId(center.id);
  return alerts.where((a) => a.severity == AlertSeverity.urgent).toList();
});
