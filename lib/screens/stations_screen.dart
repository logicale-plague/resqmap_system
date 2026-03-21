import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/index.dart';
import '../providers/index.dart';
import '../services/id_service.dart';

class StationsScreen extends ConsumerWidget {
  const StationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centerAsync = ref.watch(currentCenterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stations Management'),
        backgroundColor: Colors.indigo,
      ),
      body: centerAsync.when(
        data: (center) {
          if (center == null) {
            return const Center(child: Text('No evacuation center assigned'));
          }

          final stationsAsync = ref.watch(stationsByCenterProvider(center.id));
          return stationsAsync.when(
            data: (stations) {
              if (stations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.meeting_room,
                        size: 52,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No stations created yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _openStationDialog(context, ref, center),
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Station'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: stations.length,
                itemBuilder: (context, index) {
                  final station = stations[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: const CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Icon(Icons.meeting_room, color: Colors.white),
                      ),
                      title: Text(
                        station.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(_ageLabel(station.allowedAgeGroup)),
                              backgroundColor: Colors.blue[100],
                              labelStyle: const TextStyle(fontSize: 12),
                            ),
                            Chip(
                              label: Text(
                                _medicalLabel(station.allowedMedicalCondition),
                              ),
                              backgroundColor: Colors.orange[100],
                              labelStyle: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openStationDialog(
                              context,
                              ref,
                              center,
                              station: station,
                            );
                          } else if (value == 'delete') {
                            _confirmDelete(context, ref, station);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: centerAsync.asData?.value == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  _openStationDialog(context, ref, centerAsync.asData!.value!),
              icon: const Icon(Icons.add),
              label: const Text('Add Station'),
            ),
    );
  }

  String _ageLabel(AgeGroup? ageGroup) {
    if (ageGroup == null) return 'Any Age Group';
    switch (ageGroup) {
      case AgeGroup.child:
        return 'Children';
      case AgeGroup.adult:
        return 'Adults';
      case AgeGroup.elderly:
        return 'Elderly';
    }
  }

  String _medicalLabel(MedicalCondition? medicalCondition) {
    if (medicalCondition == null) return 'Any Condition';
    switch (medicalCondition) {
      case MedicalCondition.none:
        return 'No Condition';
      case MedicalCondition.minor:
        return 'Minor Condition';
      case MedicalCondition.serious:
        return 'Serious Condition';
    }
  }

  Future<void> _openStationDialog(
    BuildContext context,
    WidgetRef ref,
    EvacuationCenter center, {
    Station? station,
  }) async {
    final nameController = TextEditingController(text: station?.name ?? '');
    AgeGroup? selectedAgeGroup = station?.allowedAgeGroup;
    MedicalCondition? selectedMedical = station?.allowedMedicalCondition;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(station == null ? 'Add Station' : 'Edit Station'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Station Name',
                        prefixIcon: Icon(Icons.edit),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<AgeGroup?>(
                      initialValue: selectedAgeGroup,
                      decoration: const InputDecoration(
                        labelText: 'Allowed Age Group',
                        prefixIcon: Icon(Icons.people),
                      ),
                      items: [
                        const DropdownMenuItem<AgeGroup?>(
                          value: null,
                          child: Text('Any Age Group'),
                        ),
                        ...AgeGroup.values.map(
                          (ageGroup) => DropdownMenuItem<AgeGroup?>(
                            value: ageGroup,
                            child: Text(_ageLabel(ageGroup)),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedAgeGroup = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<MedicalCondition?>(
                      initialValue: selectedMedical,
                      decoration: const InputDecoration(
                        labelText: 'Allowed Medical Condition',
                        prefixIcon: Icon(Icons.local_hospital),
                      ),
                      items: [
                        const DropdownMenuItem<MedicalCondition?>(
                          value: null,
                          child: Text('Any Condition'),
                        ),
                        ...MedicalCondition.values.map(
                          (condition) => DropdownMenuItem<MedicalCondition?>(
                            value: condition,
                            child: Text(_medicalLabel(condition)),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMedical = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a station name'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) return;

    final db = ref.read(databaseServiceProvider);
    final trimmedName = nameController.text.trim();

    final stationToSave =
        (station ??
                Station(
                  id: IdService.newId(),
                  name: trimmedName,
                  evacuationCenterId: center.id,
                ))
            .copyWith(
              name: trimmedName,
              allowedAgeGroup: selectedAgeGroup,
              allowedMedicalCondition: selectedMedical,
              clearAllowedAgeGroup: selectedAgeGroup == null,
              clearAllowedMedicalCondition: selectedMedical == null,
              synced: false,
            );

    if (station == null) {
      await db.insertStation(stationToSave);
    } else {
      await db.updateStation(stationToSave);
    }

    ref.invalidate(stationsByCenterProvider(center.id));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Station station,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Station'),
          content: Text(
            'Delete "${station.name}"? Any evacuees assigned here will be unassigned.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final db = ref.read(databaseServiceProvider);
    await db.deleteStation(station.id);

    final center = ref.read(currentCenterProvider).asData?.value;
    if (center != null) {
      ref.invalidate(stationsByCenterProvider(center.id));
    }
    ref.invalidate(allEvacueesProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Station deleted')));
    }
  }
}
