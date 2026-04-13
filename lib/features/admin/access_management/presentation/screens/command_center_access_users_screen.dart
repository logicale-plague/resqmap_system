import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/core/providers/supabase_provider.dart';
import 'package:kalig_onan_evac_system/core/widgets/app_list_item_card.dart';
import 'package:kalig_onan_evac_system/features/admin/access_management/application/access_management_service.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/providers/command_center_providers.dart';
import 'package:kalig_onan_evac_system/features/authentication/data/user_dto.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/providers/user_provider.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';

final commandCenterByIdProvider = FutureProvider.family<CommandCenter?, String>(
  (ref, commandCenterId) async {
    final repository = ref.watch(commandCenterRepositoryProvider);
    return repository.getById(commandCenterId);
  },
);

final commandCenterCreatorEmailProvider =
    FutureProvider.family<String?, String?>((ref, creatorId) async {
      final selectedCreatorId = creatorId?.trim();
      if (selectedCreatorId == null || selectedCreatorId.isEmpty) {
        return null;
      }

      final supabase = ref.watch(supabaseProvider);
      final row = await supabase
          .from('users')
          .select()
          .eq('id', selectedCreatorId)
          .maybeSingle();
      if (row == null) {
        return null;
      }

      return userFromMap(Map<String, dynamic>.from(row as Map)).email;
    });

class CommandCenterAccessUsersScreen extends ConsumerWidget {
  final String? commandCenterId;

  const CommandCenterAccessUsersScreen({super.key, this.commandCenterId});

  Future<void> _removeAdminAccess(
    BuildContext context,
    WidgetRef ref,
    String commandCenterId,
    String? creatorId,
    User user,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (creatorId != null && creatorId == user.id) {
        if (!context.mounted) {
          return;
        }
        messenger.showSnackBar(
          const SnackBar(
            content: Text('You are not authorized for this action.'),
          ),
        );
        return;
      }

      final currentUser = await ref.read(currentUserProvider.future);
      final admins = await ref.read(
        commandCenterAccessUsersProvider(commandCenterId).future,
      );
      if (currentUser?.id == user.id && admins.length == 1) {
        if (!context.mounted) {
          return;
        }
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Assign another admin before removing your own access.',
            ),
          ),
        );
        return;
      }

      await ref
          .read(adminAccessManagementServiceProvider)
          .removeCommandCenterAccess(
            userId: user.id,
            commandCenterId: commandCenterId,
          );
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Removed command-center access for ${user.username}.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  // Future<void> _removeStaffAccess(
  //   BuildContext context,
  //   WidgetRef ref,
  //   String commandCenterId,
  //   StaffAccessUserWithCenters item,
  //   String evacuationCenterId,
  //   String evacuationCenterName,
  // ) async {
  //   final messenger = ScaffoldMessenger.of(context);
  //   try {
  //     await ref
  //         .read(adminAccessManagementServiceProvider)
  //         .removeEvacuationCenterAccess(
  //           userId: item.user.id,
  //           commandCenterId: commandCenterId,
  //           evacuationCenterId: evacuationCenterId,
  //         );
  //     if (!context.mounted) {
  //       return;
  //     }
  //     messenger.showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           'Removed evacuation-center access for ${item.user.username} ($evacuationCenterName).',
  //         ),
  //       ),
  //     );
  //   } catch (error) {
  //     if (!context.mounted) {
  //       return;
  //     }
  //     messenger.showSnackBar(SnackBar(content: Text(error.toString())));
  //   }
  // }

  Future<void> _promoteStaffToAdmin(
    BuildContext context,
    WidgetRef ref,
    String commandCenterId,
    User user,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(adminAccessManagementServiceProvider)
          .assignUserToCommandCenter(
            email: user.email,
            commandCenterId: commandCenterId,
          );
      if (!context.mounted) {
        return;
      }

      ref.invalidate(commandCenterAccessUsersProvider(commandCenterId));
      ref.invalidate(commandCenterStaffAccessUsersProvider(commandCenterId));

      messenger.showSnackBar(
        SnackBar(content: Text('Promoted ${user.username} to admin.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _applyStaffAccessSelection(
    BuildContext context,
    WidgetRef ref,
    String commandCenterId,
    User user,
    List<EvacuationCenter> allCenters,
    Set<String> selectedCenterIds,
    Set<String> originalCenterIds,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = ref.read(adminAccessManagementServiceProvider);

      for (final centerId in originalCenterIds.difference(selectedCenterIds)) {
        await service.removeEvacuationCenterAccess(
          userId: user.id,
          commandCenterId: commandCenterId,
          evacuationCenterId: centerId,
        );
      }

      for (final centerId in selectedCenterIds.difference(originalCenterIds)) {
        final center = allCenters.firstWhere((item) => item.id == centerId);
        await service.assignUserToEvacuationCenter(
          email: user.email,
          commandCenterId: commandCenterId,
          evacuationCenterId: center.id,
        );
      }

      if (!context.mounted) {
        return;
      }

      ref.invalidate(commandCenterStaffAccessUsersProvider(commandCenterId));
      ref.invalidate(adminUsersProvider);

      messenger.showSnackBar(
        SnackBar(content: Text('Updated access for ${user.username}.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _manageStaffAccess(
    BuildContext context,
    WidgetRef ref,
    CommandCenter commandCenter,
    StaffAccessUserWithCenters item,
  ) async {
    final allCenters = await ref.read(
      manageableEvacuationCentersByCommandCenterProvider(
        commandCenter.id,
      ).future,
    );
    if (!context.mounted) {
      return;
    }

    if (allCenters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No evacuation centers are available for this command center.',
          ),
        ),
      );
      return;
    }

    final originalCenterIds = item.evacuationCenters
        .map((center) => center.id)
        .toSet();
    final selectedCenterIds = <String>{...originalCenterIds};

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isSaving = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Manage access for ${item.user.username}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select the evacuation centers this staff member can access.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      width: double.maxFinite,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: allCenters.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final center = allCenters[index];
                          final isSelected = selectedCenterIds.contains(
                            center.id,
                          );
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: isSelected,
                            title: Text(center.name),
                            subtitle: Text(center.id),
                            onChanged: isSaving
                                ? null
                                : (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        selectedCenterIds.add(center.id);
                                      } else {
                                        selectedCenterIds.remove(center.id);
                                      }
                                    });
                                  },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() {
                            isSaving = true;
                          });
                          await _applyStaffAccessSelection(
                            context,
                            ref,
                            commandCenter.id,
                            item.user,
                            allCenters,
                            selectedCenterIds,
                            originalCenterIds,
                          );
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        elevation: 1,
        child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
      ),
    );
  }

  Widget _buildAddAccessButton(BuildContext context, String commandCenterId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: FilledButton.icon(
        onPressed: () {
          context.push(
            '/admin-access-management?commandCenterId=${Uri.encodeComponent(commandCenterId)}',
          );
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add admin/staff via email'),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    WidgetRef ref,
    String commandCenterId,
    String? creatorId,
    User user,
  ) {
    final isCreator = creatorId != null && creatorId == user.id;

    return AppListItemCard(
      margin: EdgeInsets.zero,
      elevation: 1,
      isThreeLine: true,
      leading: CircleAvatar(
        child: const Icon(Icons.admin_panel_settings_outlined),
      ),
      trailing: isCreator
          ? const Icon(Icons.verified_outlined)
          : PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'remove_admin_access') {
                  _removeAdminAccess(
                    context,
                    ref,
                    commandCenterId,
                    creatorId,
                    user,
                  );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'remove_admin_access',
                  child: Text('Remove access'),
                ),
              ],
            ),
      title: Text(
        user.username,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(user.email),
            Chip(label: Text(user.role.toCode())),
            if (isCreator) const Chip(label: Text('creator')),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard(
    BuildContext context,
    WidgetRef ref,
    String commandCenterId,
    CommandCenter commandCenter,
    StaffAccessUserWithCenters item,
  ) {
    return AppListItemCard(
      margin: EdgeInsets.zero,
      elevation: 1,
      isThreeLine: true,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.badge_outlined),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'promote_admin') {
            _promoteStaffToAdmin(context, ref, commandCenterId, item.user);
            return;
          }
          if (value == 'manage_access') {
            _manageStaffAccess(context, ref, commandCenter, item);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'promote_admin',
            child: Text('Promote to admin'),
          ),
          const PopupMenuItem<String>(
            value: 'manage_access',
            child: Text('Manage access for this user'),
          ),
        ],
      ),
      title: Text(
        item.user.username,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(item.user.email),
                Chip(label: Text(item.user.role.toCode())),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Evacuation centers',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final center in item.evacuationCenters)
                  Chip(label: Text(center.name)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCommandCenterId = commandCenterId?.trim();
    if (selectedCommandCenterId == null || selectedCommandCenterId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Command Center Access'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('No command center was selected.')),
      );
    }

    final commandCenterAsync = ref.watch(
      commandCenterByIdProvider(selectedCommandCenterId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Center Access'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: commandCenterAsync.when(
        data: (commandCenter) {
          if (commandCenter == null) {
            return const Center(
              child: Text('The selected command center could not be found.'),
            );
          }

          final adminsAsync = ref.watch(
            commandCenterAccessUsersProvider(commandCenter.id),
          );
          final staffAsync = ref.watch(
            commandCenterStaffAccessUsersProvider(commandCenter.id),
          );

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(top: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            commandCenter.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ref
                              .watch(
                                commandCenterCreatorEmailProvider(
                                  commandCenter.creatorId,
                                ),
                              )
                              .when(
                                data: (email) => Text(
                                  email ?? 'No creator email provided',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                loading: () => Text(
                                  'Loading creator email...',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                error: (_, __) => Text(
                                  'No creator email provided',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildAddAccessButton(context, commandCenter.id),
                const SizedBox(height: 16),
                _buildSectionHeader(
                  'Admins',
                  subtitle:
                      'Users with command-center access for this command center.',
                ),
                adminsAsync.when(
                  data: (users) {
                    if (users.isEmpty) {
                      return _buildEmptyState(
                        'No users currently have active command-center access for this command center.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _buildAdminCard(
                          context,
                          ref,
                          commandCenter.id,
                          commandCenter.creatorId,
                          users[index],
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Failed to load admin access users: $error'),
                  ),
                ),
                _buildSectionHeader(
                  'Staff',
                  subtitle:
                      'Users with evacuation-center access under this command center.',
                ),
                staffAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return _buildEmptyState(
                        'No staff users currently have active evacuation-center access under this command center.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _buildStaffCard(
                          context,
                          ref,
                          commandCenter.id,
                          commandCenter,
                          items[index],
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Failed to load staff access users: $error'),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load command center: $error')),
      ),
    );
  }
}
