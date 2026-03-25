import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/centers/data/evacuation_center_repository_impl.dart';

import 'package:kalig_onan_evac_system/features/centers/domain/evacuation_center.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';

final currentCenterProvider = FutureProvider<EvacuationCenter?>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getCurrentCenter();
});

final currentCommandCenterIdProvider = FutureProvider<String>((ref) async {
  final center = await ref.watch(currentCenterProvider.future);
  return center?.commandCenterId ?? 'default-command-center';
});

final allCentersProvider = FutureProvider<List<EvacuationCenter>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAllCenters();
});

final unsyncedCentersProvider = FutureProvider<List<EvacuationCenter>>((
  ref,
) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getUnsyncedCenters();
});

final centerProvider = FutureProvider.family<EvacuationCenter?, String>((
  ref,
  id,
) async {
  final db = ref.watch(databaseServiceProvider);
  final centers = await db.getAllCenters();
  try {
    return centers.firstWhere((c) => c.id == id);
  } catch (e) {
    return null;
  }
});
