import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/core/widgets/index.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/providers/command_center_providers.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/providers/user_provider.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/presentation/providers/evacuation_center_providers.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/presentation/widgets/evacuation_center_widgets.dart';

class AccessListScreen extends ConsumerWidget {
  const AccessListScreen({super.key});

  Future<List<EvacuationCenter>> _loadStaffCenters(
    WidgetRef ref,
    List<CommandCenter> assignedCommandCenters,
  ) async {
    final centerMap = <String, EvacuationCenter>{};
    for (final commandCenter in assignedCommandCenters) {
      final centers = await ref.watch(
        centersByCommandCenterProvider(commandCenter.id).future,
      );
      for (final center in centers) {
        centerMap[center.id] = center;
      }
    }

    final mergedCenters = centerMap.values.toList(growable: false);
    mergedCenters.sort((a, b) => a.name.compareTo(b.name));
    return mergedCenters;
  }

  Widget _buildAdminList(
    BuildContext context,
    WidgetRef ref,
    List<CommandCenter> commandCenters,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: commandCenters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final commandCenter = commandCenters[index];
        return AppListItemCard(
          contentPadding: const EdgeInsets.all(14),
          margin: EdgeInsets.zero,
          elevation: 1,
          isThreeLine: true,
          leading: CircleAvatar(
            backgroundColor: Colors.orange[200],
            child: const Icon(Icons.apartment, color: Colors.white),
          ),
          title: Text(
            commandCenter.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(commandCenter.email ?? 'No email provided'),
          ),
          onTap: () {
            ref
                .read(selectedCommandCenterIdProvider.notifier)
                .select(commandCenter.id);
            context.go('/admin-shell?tab=0');
          },
        );
      },
    );
  }

  Widget _buildStaffList(BuildContext context, List<EvacuationCenter> centers) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: centers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final center = centers[index];
        return AppListItemCard(
          contentPadding: const EdgeInsets.all(14),
          margin: EdgeInsets.zero,
          elevation: 1,
          isThreeLine: true,
          onTap: () => context.go('/dashboard', extra: center),
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No authenticated user found.'));
          }

          if (user.role != UserPermission.admin &&
              user.role != UserPermission.staff) {
            return const Center(
              child: Text('Access list is only available for admin and staff.'),
            );
          }

          final assignedCommandCentersAsync = ref.watch(
            assignedCommandCentersProvider,
          );
          return assignedCommandCentersAsync.when(
            data: (assignedCommandCenters) {
              if (assignedCommandCenters.isEmpty) {
                return const Center(
                  child: Text('No assigned command centers.'),
                );
              }

              if (user.role == UserPermission.admin) {
                return _buildAdminList(context, ref, assignedCommandCenters);
              }

              if (user.role == UserPermission.staff) {
                return FutureBuilder<List<EvacuationCenter>>(
                  future: _loadStaffCenters(ref, assignedCommandCenters),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return AppLoadingState();
                    }
                    if (snapshot.hasError) {
                      return AppErrorState(error: snapshot.error!);
                    }

                    final centers = snapshot.data ?? const <EvacuationCenter>[];
                    if (centers.isEmpty) {
                      return const Center(
                        child: Text(
                          'No evacuation centers under your command center access.',
                        ),
                      );
                    }
                    return _buildStaffList(context, centers);
                  },
                );
              }

              return const Center(
                child: Text(
                  'Access list is only available for admin and staff.',
                ),
              );
            },
            loading: () => AppLoadingState(),
            error: (error, _) => AppErrorState(error: error),
          );
        },
        loading: () => AppLoadingState(),
        error: (error, _) => AppErrorState(error: error),
      ),
    );
  }
}
