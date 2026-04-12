import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/core/widgets/index.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/providers/command_center_providers.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/providers/user_provider.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/presentation/helpers/center_navigation.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/presentation/widgets/evacuation_center_widgets.dart';

class AccessListScreen extends ConsumerWidget {
  const AccessListScreen({super.key});

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
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'manage_access') {
                context.push(
                  '/admin-command-center-access-users?commandCenterId=${Uri.encodeComponent(commandCenter.id)}',
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'manage_access',
                child: Text('Manage access'),
              ),
            ],
          ),
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
            context.push('/admin-shell?tab=0');
          },
        );
      },
    );
  }

  Widget _buildStaffList(
    BuildContext context,
    WidgetRef ref,
    List<EvacuationCenter> centers,
  ) {
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
          onTap: () => openCenterDashboard(context, ref, center),
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

          final headerChildren = <Widget>[];

          // if (user.role == UserPermission.admin) {
          //   headerChildren.add(
          //     Padding(
          //       padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          //       child: FilledButton.icon(
          //         onPressed: () => context.push('/admin-access-management'),
          //         icon: const Icon(Icons.manage_accounts_outlined),
          //         label: const Text('Manage access'),
          //       ),
          //     ),
          //   );
          // }

          if (user.role == UserPermission.staff) {
            final staffCentersAsync = ref.watch(staffAssignedCentersProvider);
            return staffCentersAsync.when(
              data: (centers) {
                if (centers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No evacuation centers assigned to your account.',
                    ),
                  );
                }
                return Column(
                  children: [
                    if (headerChildren.isNotEmpty) ...headerChildren,
                    Expanded(child: _buildStaffList(context, ref, centers)),
                  ],
                );
              },
              loading: () => AppLoadingState(),
              error: (error, _) => AppErrorState(error: error),
            );
          }

          final assignedCommandCentersAsync = ref.watch(
            assignedCommandCentersProvider,
          );
          return assignedCommandCentersAsync.when(
            data: (assignedCommandCenters) {
              if (user.role == UserPermission.admin) {
                return Column(
                  children: [
                    if (headerChildren.isNotEmpty) ...headerChildren,
                    Expanded(
                      child: assignedCommandCenters.isEmpty
                          ? const Center(
                              child: Text('No assigned command centers.'),
                            )
                          : _buildAdminList(
                              context,
                              ref,
                              assignedCommandCenters,
                            ),
                    ),
                  ],
                );
              }

              if (assignedCommandCenters.isEmpty) {
                return const Center(
                  child: Text('No assigned command centers.'),
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
