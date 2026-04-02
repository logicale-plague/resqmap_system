import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/supabase_provider.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/data/command_center_dto.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final updateCommandCenterProvider = Provider<UpdateCommandCenterUseCase>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return UpdateCommandCenterUseCase(supabaseClient: supabase);
});

class UpdateCommandCenterUseCase {
  final SupabaseClient _supabaseClient;

  UpdateCommandCenterUseCase({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

  Future<void> updateCommandCenter(CommandCenter center) async {
    await _supabaseClient
        .from('command_centers')
        .update(commandCenterToRemoteMap(center))
        .eq('id', center.id);
  }
}
