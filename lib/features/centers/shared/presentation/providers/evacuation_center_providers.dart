import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/supabase_provider.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/application/register_center.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/application/update_center.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/data/evacuation_center_repository_impl.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center_repository.dart';

final evacuationCenterRepositoryProvider = Provider<EvacuationCenterRepository>(
  (ref) {
    final db = ref.watch(databaseServiceProvider);
    final supabase = ref.watch(supabaseProvider);
    final registerCenter = ref.watch(registerCenterProvider);
    final updateCenter = ref.watch(updateCenterCapacityProvider);
    return EvacuationCenterRepositoryImpl(
      db,
      supabaseClient: supabase,
      registerCenter: registerCenter,
      updateCenterCapacity: updateCenter,
    );
  },
);

final currentCenterProvider = FutureProvider<EvacuationCenter?>((ref) async {
  final repository = ref.watch(evacuationCenterRepositoryProvider);
  return repository.getCurrent();
});

final allCentersProvider = FutureProvider<List<EvacuationCenter>>((ref) async {
  final repository = ref.watch(evacuationCenterRepositoryProvider);
  return repository.getAll();
});

final unsyncedCentersProvider = FutureProvider<List<EvacuationCenter>>((
  ref,
) async {
  final repository = ref.watch(evacuationCenterRepositoryProvider);
  return repository.getUnsynced();
});

final centerProvider = FutureProvider.family<EvacuationCenter?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(evacuationCenterRepositoryProvider);
  return repository.getById(id);
});

final centersByCommandCenterProvider =
    FutureProvider.family<List<EvacuationCenter>, String>((
      ref,
      commandCenterId,
    ) async {
      final repository = ref.watch(evacuationCenterRepositoryProvider);
      return repository.getByCommandCenterId(commandCenterId);
    });
