import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/index.dart';
import '../providers/index.dart';
import 'widgets/screen_components.dart';
import 'widgets/index.dart';

class CentersScreen extends ConsumerWidget {
  const CentersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centersAsync = ref.watch(allCentersProvider);

    return Scaffold(
      appBar: buildScreenAppBar(title: 'Evacuation Centers'),
      body: centersAsync.when(
        data: (centers) {
          if (centers.isEmpty) {
            return AppEmptyState(
              icon: Icons.home_work_outlined,
              message: 'No evacuation centers yet',
              action: ElevatedButton.icon(
                onPressed: () => context.push('/map'),
                icon: const Icon(Icons.map_outlined),
                label: const Text('View Map'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: centers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final center = centers[index];
              return AppListItemCard(
                contentPadding: const EdgeInsets.all(14),
                margin: EdgeInsets.zero,
                elevation: 1,
                leading: CircleAvatar(
                  backgroundColor: _statusColor(center.status),
                  child: const Icon(Icons.apartment, color: Colors.white),
                ),
                title: Text(
                  center.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppTagChip(
                        label:
                            '${center.currentOccupancy} / ${center.totalCapacity} occupied',
                        color: Colors.blue[100]!,
                      ),
                      AppTagChip(
                        label: _statusText(center.status),
                        color: _statusColor(center.status).withAlpha(55),
                      ),
                      AppTagChip(
                        label: center.medicalAvailable
                            ? 'Medical available'
                            : 'No medical services',
                        color: center.medicalAvailable
                            ? Colors.green[100]!
                            : Colors.red[100]!,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const AppLoadingState(),
        error: (err, _) =>
            AppErrorState(error: err, prefix: 'Error loading centers'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/map'),
        icon: const Icon(Icons.map),
        label: const Text('View Map'),
      ),
    );
  }

  String _statusText(CenterStatus status) {
    switch (status) {
      case CenterStatus.operational:
        return 'Operational';
      case CenterStatus.nearCapacity:
        return 'Near Capacity';
      case CenterStatus.atCapacity:
        return 'At Capacity';
      case CenterStatus.closed:
        return 'Closed';
    }
  }

  Color _statusColor(CenterStatus status) {
    switch (status) {
      case CenterStatus.operational:
        return Colors.green;
      case CenterStatus.nearCapacity:
        return Colors.orange;
      case CenterStatus.atCapacity:
        return Colors.red;
      case CenterStatus.closed:
        return Colors.grey;
    }
  }
}
