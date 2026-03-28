import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/exceptions/offline_exception.dart';
import 'package:kalig_onan_evac_system/core/providers/connectivity_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/supabase_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/centers/data/evacuation_center_db_extension.dart';
import 'package:kalig_onan_evac_system/features/centers/data/evacuation_center_dto.dart';
import 'package:kalig_onan_evac_system/features/centers/domain/evacuation_center.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final registerCenterProvider = Provider<RegisterCenterUseCase>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final supabaseService = ref.watch(supabaseProvider);
  return RegisterCenterUseCase(
    databaseService: dbService,
    supabaseService: supabaseService,
    ref: ref,
  );
});

class RegisterCenterUseCase {
  final DatabaseService _databaseService;
  final SupabaseClient _supabaseService;
  final Ref _ref;

  RegisterCenterUseCase({
    required DatabaseService databaseService,
    required SupabaseClient supabaseService,
    required Ref ref,
  }) : _databaseService = databaseService,
       _supabaseService = supabaseService,
       _ref = ref;

  /// Registers a center to Supabase and pulls it to the local database.
  ///
  /// Throws [OfflineException] if the device has no internet access.
  Future<void> registerCenter(EvacuationCenter center) async {
    final isOnline = await _ref.read(isOnlineProvider.future);

    if (!isOnline) {
      throw OfflineException(
        'An internet connection is required to register an evacuation center.',
      );
    }

    await _supabaseService
        .from('evacuation_centers')
        .insert(centerToMap(center));

    await _databaseService.upsertCenterFromRemote(
      center.copyWith(synced: true),
    );
  }
}
