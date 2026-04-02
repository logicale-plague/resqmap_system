import 'package:kalig_onan_evac_system/features/admin/command_center/application/update_command_center.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/data/command_center_dto.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommandCenterRepositoryImpl implements CommandCenterRepository {
  final SupabaseClient _supabaseClient;
  final UpdateCommandCenterUseCase _updateCommandCenter;

  CommandCenterRepositoryImpl({
    required SupabaseClient supabaseClient,
    required UpdateCommandCenterUseCase updateCommandCenter,
  }) : _supabaseClient = supabaseClient,
       _updateCommandCenter = updateCommandCenter;

  @override
  Future<List<CommandCenter>> getAll() async {
    final rows = await _supabaseClient.from('command_centers').select();
    return [for (final row in rows) commandCenterFromRemoteMap(row)];
  }

  @override
  Future<CommandCenter?> getCurrent() async {
    final rows = await _supabaseClient
        .from('command_centers')
        .select()
        .eq('is_active', 1)
        .limit(1);

    if (rows.isEmpty) {
      return null;
    }

    return commandCenterFromRemoteMap(rows.first);
  }

  @override
  Future<CommandCenter?> getById(String id) async {
    final rows = await _supabaseClient
        .from('command_centers')
        .select()
        .eq('id', id)
        .limit(1);

    if (rows.isEmpty) {
      return null;
    }

    return commandCenterFromRemoteMap(rows.first);
  }

  @override
  Future<void> update(CommandCenter center) {
    return _updateCommandCenter.updateCommandCenter(center);
  }
}
