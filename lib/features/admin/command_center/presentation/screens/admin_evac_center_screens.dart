import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/providers/command_center_providers.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/index.dart';

import '../../../../../core/widgets/index.dart';

class AdminEvacCenterScreens extends ConsumerStatefulWidget {
  const AdminEvacCenterScreens({super.key});

  @override
  ConsumerState<AdminEvacCenterScreens> createState() =>
      _AdminEvacCenterScreensState();
}

class _AdminEvacCenterScreensState
    extends ConsumerState<AdminEvacCenterScreens> {
  @override
  Widget build(BuildContext context) {
    final currentCommandCenterAsync = ref.watch(currentCommandCenterProvider);

    return currentCommandCenterAsync.when(
      data: (currentCommandCenter) {
        if (currentCommandCenter == null) {
          return AppEmptyState(
            icon: Icons.apartment_outlined,
            message:
                'Select a command center in the Command Centers tab to view evacuation centers.',
            action: ElevatedButton.icon(
              onPressed: () => context.go('/admin-shell?tab=0'),
              icon: const Icon(Icons.apartment_outlined),
              label: const Text('Go To Command Centers'),
            ),
          );
        }

        final centersAsync = ref.watch(
          centersByCommandCenterProvider(currentCommandCenter.id),
        );

        return AsyncDataBuilder<List<EvacuationCenter>>(
          asyncValue: centersAsync,
          errorPrefix: 'Error loading centers',
          builder: (centers) {
            if (centers.isEmpty) {
              return AppEmptyState(
                icon: Icons.home_work_outlined,
                message: 'No evacuation centers yet',
                action: ElevatedButton.icon(
                  onPressed: () => context.go('/admin-shell?tab=2'),
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
                  isThreeLine: true,
                  leading: CircleAvatar(
                    backgroundColor: statusColor(center.status),
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
                          label: statusText(center.status),
                          color: statusColor(center.status).withAlpha(55),
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
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => AppEmptyState(
        icon: Icons.error_outline,
        message: 'Unable to load selected command center.',
        action: ElevatedButton.icon(
          onPressed: () => context.go('/admin-shell?tab=0'),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ),
    );
  }
}
