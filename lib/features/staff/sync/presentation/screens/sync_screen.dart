import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/indices/provider_index.dart';
import 'package:kalig_onan_evac_system/core/widgets/index.dart';
import 'package:kalig_onan_evac_system/features/staff/sync/application/sync_service.dart';
import 'package:kalig_onan_evac_system/features/staff/sync/presentation/widgets/sync_widgets.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  bool _isSimulating = false;

  Future<void> _startSync() async {
    setState(() => _isSimulating = true);

    final syncService = ref.read(syncServiceProvider);
    syncService.setOnlineStatus(true);

    try {
      await syncService.syncNow();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSimulating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!mounted) return;

    setState(() => _isSimulating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data synced successfully with command center'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unsyncedCenters = ref.watch(unsyncedCentersProvider);
    final unsyncedEvacuees = ref.watch(unsyncedEvacueesProvider);
    final unsyncedSupplies = ref.watch(unsyncedSuppliesProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      // appBar: buildScreenAppBar(title: 'Sync Status'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            syncStatus.when(
              data: (isOnline) => buildConnectionStatusBox(isOnline),
              loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
            const SizedBox(height: 32),
            Text('Sync Status', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            unsyncedCenters.when(
              data: (centers) => unsyncedEvacuees.when(
                data: (evacuees) => unsyncedSupplies.when(
                  data: (supplies) {
                    final pendingCount =
                        centers.length + evacuees.length + supplies.length;
                    return InfoContainer.warning(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.pending_actions,
                            color: Colors.yellow[700],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pending Updates',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.yellow[900],
                                  ),
                                ),
                                Text(
                                  '$pendingCount record(s) waiting to sync',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.yellow[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Centers: ${centers.length} \u2022 '
                                  'Evacuees: ${evacuees.length} \u2022 '
                                  'Supplies: ${supplies.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.yellow[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
            const SizedBox(height: 16),
            InfoContainer.info(
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Sync',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                          ),
                        ),
                        Text(
                          'Check sync details above',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How Sync Works',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  buildBulletPoint(
                    'All data changes are saved locally on this device',
                  ),
                  buildBulletPoint(
                    'When connection is restored, data automatically syncs',
                  ),
                  buildBulletPoint(
                    'Command center receives all pending updates',
                  ),
                  buildBulletPoint(
                    'Conflicts are resolved automatically when possible',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSimulating ? null : _startSync,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSimulating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'SYNC NOW',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
