import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/index.dart';

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
      appBar: AppBar(
        title: const Text('Evacuees List'),
        backgroundColor: Colors.indigo,
      ),
      body: evacueesAsync.when(
        data: (evacuees) {
          final stationsById = <String, Station>{
            for (final station in stationsAsync.value ?? [])
              station.id: station,
          };

          if (evacuees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No evacuees registered',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: evacuees.length,
            itemBuilder: (context, index) {
              final evacuee = evacuees[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
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
                          Chip(
                            label: Text(_getAgeGroupDisplay(evacuee.ageGroup)),
                            backgroundColor: Colors.blue[100],
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              _getMedicalConditionDisplay(
                                evacuee.medicalCondition,
                              ),
                            ),
                            backgroundColor: _getMedicalConditionColor(
                              evacuee.medicalCondition,
                            ).withAlpha(80),
                            labelStyle: const TextStyle(fontSize: 12),
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
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
