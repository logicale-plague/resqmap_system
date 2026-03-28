import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/evacuees/application/register_evacuee.dart';
import 'package:kalig_onan_evac_system/features/evacuees/application/update_evacuee.dart';
import 'package:kalig_onan_evac_system/features/evacuees/data/evacuee_db_extension.dart';
import 'package:kalig_onan_evac_system/features/evacuees/data/evacuee_repository_impl.dart';

import 'package:kalig_onan_evac_system/features/evacuees/domain/evacuee.dart';
import 'package:kalig_onan_evac_system/features/evacuees/domain/evacuee_repository.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';

final evacueeRepositoryProvider = Provider<EvacueeRepository>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final registerEvacuee = ref.watch(registerEvacueeUseCaseProvider);
  final updateEvacuee = ref.watch(updateEvacueeProvider);

  return EvacueeRepositoryImpl(
    db,
    registerEvacueeUseCase: registerEvacuee,
    updateEvacueeUseCase: updateEvacuee,
  );
});

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
  return db.getEvacueeById(id);
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
