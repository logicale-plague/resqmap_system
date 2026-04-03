import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/exceptions/offline_exception.dart';
import 'package:kalig_onan_evac_system/core/providers/connectivity_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/supabase_provider.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/index.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/data/station_db_extension.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/data/station_dto.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/domain/station.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/presentation/providers/station_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final registerStationProvider = Provider<RegisterStationUseCase>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final supabase = ref.watch(supabaseProvider);
  return RegisterStationUseCase(
    databaseService: db,
    supabaseService: supabase,
    ref: ref,
  );
});

class RegisterStationUseCase {
  final DatabaseService _databaseService;
  final SupabaseClient _supabaseService;
  final Ref _ref;

  RegisterStationUseCase({
    required DatabaseService databaseService,
    required SupabaseClient supabaseService,
    required Ref ref,
  }) : _databaseService = databaseService,
       _supabaseService = supabaseService,
       _ref = ref;

  Future<void> registerStation(Station station) async {
    final isOnline = await _ref.refresh(isOnlineProvider.future);

    if (!isOnline) {
      throw OfflineException(
        'An internet connection is required to register a station.',
      );
    }
    final payload = stationToRemoteMap(station)
      ..remove('synced')
      ..['name'] = station.name.trim();

    await _supabaseService.from('stations').insert(payload);
    await _databaseService.upsertStationFromRemote(
      station.copyWith(name: station.name.trim(), synced: true),
    );

    // Invalidate all related providers so new station is reflected everywhere
    _ref.invalidate(currentCenterProvider);
    // Invalidate all instances of stationsByCenterProvider and eligibleStationsProvider
    // This ensures the registration screen and stations list see the new station
    _ref.invalidate(stationsByCenterProvider(station.evacuationCenterId));
    _ref.invalidate(eligibleStationsProvider);
  }
}
