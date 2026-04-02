import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/supabase_provider.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/data/command_center_repository_impl.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center_repository.dart';

final commandCenterRepositoryProvider = Provider<CommandCenterRepository>((
  ref,
) {
  final supabase = ref.watch(supabaseProvider);
  return CommandCenterRepositoryImpl(supabaseClient: supabase);
});

final allCommandCentersProvider = FutureProvider((ref) async {
  final repository = ref.watch(commandCenterRepositoryProvider);
  return repository.getAll();
});

final selectedCommandCenterIdProvider =
    NotifierProvider<SelectedCommandCenterIdNotifier, String?>(
      SelectedCommandCenterIdNotifier.new,
    );

class SelectedCommandCenterIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? commandCenterId) {
    state = commandCenterId;
  }
}

final currentCommandCenterProvider = FutureProvider<CommandCenter?>((
  ref,
) async {
  final selectedCommandCenterId = ref.watch(selectedCommandCenterIdProvider);
  if (selectedCommandCenterId == null) {
    return null;
  }

  final repository = ref.watch(commandCenterRepositoryProvider);
  return repository.getById(selectedCommandCenterId);
});
