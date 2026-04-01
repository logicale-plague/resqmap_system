import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';
import 'package:kalig_onan_evac_system/features/staff/centers/application/register_center.dart';
import 'package:kalig_onan_evac_system/features/staff/centers/application/update_center.dart';
import 'package:kalig_onan_evac_system/features/staff/centers/data/evacuation_center_repository_impl.dart';
import 'package:kalig_onan_evac_system/features/staff/centers/domain/evacuation_center_repository.dart';

final evacuationCenterRepositoryProvider = Provider<EvacuationCenterRepository>(
  (ref) {
    final db = ref.watch(databaseServiceProvider);
    final registerCenter = ref.watch(registerCenterProvider);
    final updateCenter = ref.watch(updateCenterCapacityProvider);
    return EvacuationCenterRepositoryImpl(
      db,
      registerCenter: registerCenter,
      updateCenterCapacity: updateCenter,
    );
  },
);

final currentCenterProvider = FutureProvider<EvacuationCenter?>((ref) async {
  final repository = ref.watch(evacuationCenterRepositoryProvider);
  return repository.getCurrent();
});

final currentCommandCenterIdProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(evacuationCenterRepositoryProvider);
  return repository.getCurrentCommandCenterId();
});

final allCentersProvider = FutureProvider<List<EvacuationCenter>>((ref) async {
  final repository = ref.watch(evacuationCenterRepositoryProvider);
  return repository.getAll();
});

final unsyncedCentersProvider = FutureProvider<List<EvacuationCenter>>((
  ref,
) async {
  final repository = ref.watch(evacuationCenterRepositoryProvider);
  return repository.getAll().then(
    (centers) => centers.where((center) => !center.synced).toList(),
  );
});

final centerProvider = FutureProvider.family<EvacuationCenter?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(evacuationCenterRepositoryProvider);
  return repository.getById(id);
});
