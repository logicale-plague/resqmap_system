import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/exceptions/offline_exception.dart';
import 'package:kalig_onan_evac_system/core/providers/connectivity_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/supabase_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/stations/data/station_db_extension.dart';
import 'package:kalig_onan_evac_system/features/stations/domain/station.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final registerStationProvider = Provider<RegisterStationService>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final supabase = ref.watch(supabaseProvider);
  return RegisterStationService(
    databaseService: db,
    supabaseService: supabase,
    ref: ref,
  );
});

class RegisterStationService {
  final DatabaseService _databaseService;
  final SupabaseClient _supabaseService;
  final Ref? _ref;

  RegisterStationService({
    DatabaseService? databaseService,
    SupabaseClient? supabaseService,
    Ref? ref,
  }) : _databaseService = databaseService ?? DatabaseService(),
       _supabaseService = supabaseService ?? Supabase.instance.client,
       _ref = ref;

  Future<void> registerStation(Station station) async {
    final isOnline = _ref != null
        ? await _ref.read(isOnlineProvider.future)
        : isOnlineProvider.future as bool;

    if (!isOnline) {
      throw OfflineException(
        'An internet connection is required to register a station.',
      );
    }
    await _supabaseService.from('stations').insert({
      'id': station.id,
      'name': station.name.trim(),
    });
    await _databaseService.upsertStationFromRemote(
      station.copyWith(synced: true),
    );
  }
}
