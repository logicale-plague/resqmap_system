import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/sync/application/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

final syncStatusProvider = StreamProvider<bool>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStatusStream;
});
