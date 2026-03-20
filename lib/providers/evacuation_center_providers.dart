import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/evacuation_center.dart';
import 'database_provider.dart';

final currentCenterProvider = FutureProvider<EvacuationCenter?>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getCurrentCenter();
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
