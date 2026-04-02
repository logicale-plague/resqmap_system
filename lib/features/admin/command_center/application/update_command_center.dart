import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center_repository.dart';

class UpdateCommandCenterUseCase {
  final CommandCenterRepository _repository;

  UpdateCommandCenterUseCase({required CommandCenterRepository repository})
    : _repository = repository;

  Future<void> updateCommandCenter(CommandCenter center) async {
    await _repository.update(center);
  }
}
