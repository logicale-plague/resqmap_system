import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/evacuees/data/evacuee_repository_impl.dart';

import 'package:kalig_onan_evac_system/features/evacuees/domain/evacuee.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';

final allEvacueesProvider = FutureProvider<List<Evacuee>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAllEvacuees();
});

final evacueeCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getEvacueeCount();
});

final unsyncedEvacueesProvider = FutureProvider<List<Evacuee>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getUnsyncedEvacuees();
});

final evacueeProvider = FutureProvider.family<Evacuee?, String>((
  ref,
  id,
) async {
  final db = ref.watch(databaseServiceProvider);
  final evacuees = await db.getAllEvacuees();
  try {
    return evacuees.firstWhere((e) => e.id == id);
  } catch (e) {
    return null;
  }
});

final unnamedEvacueesByStationProvider =
    FutureProvider.family<List<Evacuee>, String>((ref, stationId) async {
      final db = ref.watch(databaseServiceProvider);
      return db.getUnnamedEvacueesByStation(stationId);
    });

final evacueeCountByStationProvider = FutureProvider.family<int, String>((
  ref,
  stationId,
) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getEvacueeCountByStation(stationId);
});
