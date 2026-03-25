import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/alerts/data/alert_repository_impl.dart';

import 'package:kalig_onan_evac_system/features/alerts/domain/alert.dart';
import 'package:kalig_onan_evac_system/features/alerts/domain/alert_repository.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/features/centers/presentation/providers/evacuation_center_providers.dart';

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return AlertRepositoryImpl(db);
});

final allAlertsProvider = FutureProvider<List<Alert>>((ref) async {
  final repository = ref.watch(alertRepositoryProvider);
  final center = await ref.watch(currentCenterProvider.future);
  if (center == null) return [];
  return repository.getByCenterId(center.id);
});

final unsyncedAlertsProvider = FutureProvider<List<Alert>>((ref) async {
  final repository = ref.watch(alertRepositoryProvider);
  return repository.getUnsynced();
});

final alertProvider = FutureProvider.family<Alert?, String>((ref, id) async {
  final repository = ref.watch(alertRepositoryProvider);
  return repository.getById(id);
});

final unreadAlertsProvider = FutureProvider<List<Alert>>((ref) async {
  final alerts = await ref.watch(allAlertsProvider.future);
  return alerts.where((a) => !a.read).toList();
});

final urgentAlertsProvider = FutureProvider<List<Alert>>((ref) async {
  final alerts = await ref.watch(allAlertsProvider.future);
  return alerts.where((a) => a.severity == AlertSeverity.urgent).toList();
});
