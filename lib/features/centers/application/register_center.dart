import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/supabase_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/centers/data/evacuation_center_dto.dart';
import 'package:kalig_onan_evac_system/features/centers/data/evacuation_center_repository_impl.dart';
import 'package:kalig_onan_evac_system/features/centers/domain/evacuation_center.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final registerCenterProvider = Provider<RegisterCenter>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final supabaseService = ref.watch(supabaseProvider);
  return RegisterCenter(
    databaseService: databaseService,
    supabaseService: supabaseService,
  );
});

class RegisterCenter {
  final DatabaseService _databaseService;
  final SupabaseClient _supabaseService;

  RegisterCenter({
    DatabaseService? databaseService,
    SupabaseClient? supabaseService,
  }) : _databaseService = databaseService ?? DatabaseService(),
       _supabaseService = supabaseService ?? Supabase.instance.client;

  Future<void> registerCenter(EvacuationCenter center) async {
    await _supabaseService
        .from('evacuation_centers')
        .insert(centerToMap(center));
    await _databaseService.upsertCenterFromRemote(
      center.copyWith(synced: true),
    );
  }
}
