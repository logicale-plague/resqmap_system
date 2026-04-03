import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/staff/sync/application/sync_service.dart';

final syncStatusProvider = StreamProvider<bool>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return () async* {
    // Provide an immediate first value so consumers don't stay in loading
    // while waiting for connectivity/bootstrap events.
    yield syncService.isOnline;
    yield* syncService.syncStatusStream;
  }();
});
