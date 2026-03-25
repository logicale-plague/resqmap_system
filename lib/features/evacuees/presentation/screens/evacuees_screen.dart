import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/indices/models_index.dart';
import 'package:kalig_onan_evac_system/core/indices/provider_index.dart';
import 'package:kalig_onan_evac_system/core/widgets/index.dart';
import 'package:kalig_onan_evac_system/features/evacuees/application/remove_evacuee.dart';

class EvacueesScreen extends ConsumerWidget {
  const EvacueesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evacueesAsync = ref.watch(allEvacueesProvider);
    final centerAsync = ref.watch(currentCenterProvider);
    final currentCenter = centerAsync.asData?.value;
    final stationsAsync = currentCenter == null
        ? const AsyncValue<List<Station>>.data([])
        : ref.watch(stationsByCenterProvider(currentCenter.id));

    return Scaffold(
      appBar: buildScreenAppBar(title: 'Evacuees List'),
      body: evacueesAsync.when(
        data: (evacuees) {
          final stationsById = <String, Station>{
            for (final station in stationsAsync.value ?? [])
              station.id: station,
          };

          if (evacuees.isEmpty) {
            return const AppEmptyState(
              icon: Icons.people,
              message: 'No evacuees registered',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: evacuees.length,
            itemBuilder: (context, index) {
              final evacuee = evacuees[index];
              return AppListItemCard(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    evacuee.name?.isNotEmpty == true
                        ? evacuee.name![0].toUpperCase()
                        : evacuee.id.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  evacuee.name ?? 'ID: ${evacuee.id.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AppTagChip(
                          label: _getAgeGroupDisplay(evacuee.ageGroup),
                          color: Colors.blue[100]!,
                        ),
                        const SizedBox(width: 8),
                        AppTagChip(
                          label: _getMedicalConditionDisplay(
                            evacuee.medicalCondition,
                          ),
                          color: _getMedicalConditionColor(
                            evacuee.medicalCondition,
                          ).withAlpha(80),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Registered: ${evacuee.registeredAt.toLocal().toString().substring(0, 16)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (evacuee.stationId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Station: ${stationsById[evacuee.stationId!]?.name ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _showDeleteDialog(context, ref, evacuee);
                  },
                ),
              );
            },
          );
        },
        loading: () => const AppLoadingState(),
        error: (err, stack) => AppErrorState(error: err, stackTrace: stack),
      ),
    );
  }

  String _getAgeGroupDisplay(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'Child';
      case AgeGroup.adult:
        return 'Adult';
      case AgeGroup.elderly:
        return 'Elderly';
    }
  }

  String _getMedicalConditionDisplay(MedicalCondition condition) {
    switch (condition) {
      case MedicalCondition.none:
        return 'None';
      case MedicalCondition.minor:
        return 'Minor';
      case MedicalCondition.serious:
        return 'Serious';
    }
  }

  Color _getMedicalConditionColor(MedicalCondition condition) {
    switch (condition) {
      case MedicalCondition.none:
        return Colors.green;
      case MedicalCondition.minor:
        return Colors.orange;
      case MedicalCondition.serious:
        return Colors.red;
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Evacuee evacuee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Evacuee'),
        content: Text(
          'Are you sure you want to remove ${evacuee.name ?? 'this evacuee'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseServiceProvider);
              await db.removeEvacuee(evacuee.id);
              if (!context.mounted) return;
              Navigator.pop(context);
              ref.invalidate(allEvacueesProvider);
              ref.invalidate(evacueeCountProvider);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Evacuee removed')));
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
