import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/connectivity_provider.dart';
import 'package:kalig_onan_evac_system/features/staff/sync/application/sync_service.dart';

/// Wires connectivity state to SyncService so pending local data
/// is synchronized automatically when internet access is restored.
final autoSyncBootstrapProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
    final syncService = ref.read(syncServiceProvider);

    next.when(
      data: (isOnline) => syncService.setOnlineStatus(isOnline),
      loading: () {},
      error: (_, __) => syncService.setOnlineStatus(false),
    );
  }, fireImmediately: true);
});
