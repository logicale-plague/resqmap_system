import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/core/widgets/app_list_item_card.dart';
import 'package:kalig_onan_evac_system/features/admin/access_management/application/access_management_service.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/providers/command_center_providers.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/providers/user_provider.dart';

final commandCenterByIdProvider = FutureProvider.family<CommandCenter?, String>(
  (ref, commandCenterId) async {
    final repository = ref.watch(commandCenterRepositoryProvider);
    return repository.getById(commandCenterId);
  },
);

class CommandCenterAccessUsersScreen extends ConsumerWidget {
  final String? commandCenterId;

  const CommandCenterAccessUsersScreen({super.key, this.commandCenterId});

  Future<void> _removeAdminAccess(
    BuildContext context,
    WidgetRef ref,
    String commandCenterId,
    User user,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
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

  Future<void> _removeStaffAccess(
    BuildContext context,
    WidgetRef ref,
    String commandCenterId,
    StaffAccessUserWithCenters item,
    String evacuationCenterId,
    String evacuationCenterName,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(adminAccessManagementServiceProvider)
          .removeEvacuationCenterAccess(
            userId: item.user.id,
            commandCenterId: commandCenterId,
            evacuationCenterId: evacuationCenterId,
          );
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Removed evacuation-center access for ${item.user.username} ($evacuationCenterName).',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

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
    User user,
  ) {
    return AppListItemCard(
      margin: EdgeInsets.zero,
      elevation: 1,
      isThreeLine: true,
      leading: CircleAvatar(
        child: const Icon(Icons.admin_panel_settings_outlined),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'remove_admin_access') {
            _removeAdminAccess(context, ref, commandCenterId, user);
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
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard(
    BuildContext context,
    WidgetRef ref,
    String commandCenterId,
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
          if (value.startsWith('remove_center:')) {
            final evacuationCenterId = value.substring('remove_center:'.length);
            final centerName = item.evacuationCenters
                .firstWhere(
                  (center) => center.id == evacuationCenterId,
                  orElse: () => item.evacuationCenters.first,
                )
                .name;
            _removeStaffAccess(
              context,
              ref,
              commandCenterId,
              item,
              evacuationCenterId,
              centerName,
            );
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'promote_admin',
            child: Text('Promote to admin'),
          ),
          const PopupMenuDivider(),
          for (final center in item.evacuationCenters)
            PopupMenuItem<String>(
              value: 'remove_center:${center.id}',
              child: Text('Remove ${center.name} access'),
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
                          Text(
                            commandCenter.email ?? 'No email provided',
                            style: TextStyle(color: Colors.grey.shade700),
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
