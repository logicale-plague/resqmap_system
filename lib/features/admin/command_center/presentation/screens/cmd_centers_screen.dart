import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/core/widgets/index.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/providers/command_center_providers.dart';

class CmdCentersScreen extends ConsumerStatefulWidget {
  const CmdCentersScreen({super.key});

  @override
  ConsumerState<CmdCentersScreen> createState() => _CmdCentersScreenState();
}

class _CmdCentersScreenState extends ConsumerState<CmdCentersScreen> {
  @override
  Widget build(BuildContext context) {
    final cmdCentersAsync = ref.watch(assignedCommandCentersProvider);
    final selectedCommandCenterId = ref.watch(selectedCommandCenterIdProvider);

    return Scaffold(
      body: AsyncDataBuilder<List<CommandCenter>>(
        asyncValue: cmdCentersAsync,
        errorPrefix: 'Error loading command centers',
        builder: (cmdCenters) {
          if (cmdCenters.isEmpty) {
            return const AppEmptyState(
              icon: Icons.apartment_outlined,
              message: 'No assigned command centers',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: cmdCenters.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cmdCenter = cmdCenters[index];
              final isSelected = selectedCommandCenterId == cmdCenter.id;
              return AppListItemCard(
                contentPadding: const EdgeInsets.all(14),
                margin: EdgeInsets.zero,
                elevation: 1,
                isThreeLine: true,
                leftBorderColor: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.orange[200],
                  child: const Icon(Icons.apartment, color: Colors.white),
                ),
                title: Text(
                  cmdCenter.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(cmdCenter.creatorId ?? 'No creator ID provided'),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  ref
                      .read(selectedCommandCenterIdProvider.notifier)
                      .select(cmdCenter.id);
                  context.go('/admin-shell?tab=0');
                },
              );
            },
          );
        },
      ),
    );
  }
}
