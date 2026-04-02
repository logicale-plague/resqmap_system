import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center_repository.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/providers/command_center_providers.dart';

final updateCommandCenterUseCaseProvider = Provider<UpdateCommandCenterUseCase>(
  (ref) {
    final repository = ref.watch(commandCenterRepositoryProvider);
    return UpdateCommandCenterUseCase(repository: repository);
  },
);

class UpdateCommandCenterUseCase {
  final CommandCenterRepository _repository;

  UpdateCommandCenterUseCase({required CommandCenterRepository repository})
    : _repository = repository;

  Future<void> updateCommandCenter(CommandCenter center) async {
    await _repository.update(center);
  }
}
