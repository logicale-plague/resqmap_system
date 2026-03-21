import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/index.dart';
import '../providers/index.dart';
import '../services/id_service.dart';
import 'widgets/screen_components.dart';

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
                  final occupancyAsync = ref.watch(
                    evacueeCountByStationProvider(station.id),
                  );
                  final occupancyCount = occupancyAsync.asData?.value ?? 0;
                  final occupancyColor = _occupancyChipColor(
                    occupancyCount,
                    station.capacity,
                  );
                  final unnamedAsync = ref.watch(
                    unnamedEvacueesByStationProvider(station.id),
                  );
                  final unnamedCount = unnamedAsync.asData?.value.length ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      onTap: () =>
                          _openStationArrivalsSheet(context, ref, station),
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
                            AppTagChip(
                              label: 'Cap: ${station.capacity}',
                              color: Colors.green[100]!,
                            ),
                            AppTagChip(
                              label: '$occupancyCount / ${station.capacity}',
                              color: occupancyColor.withAlpha(60),
                            ),
                            AppTagChip(
                              label: _ageLabel(station.allowedAgeGroup),
                              color: Colors.blue[100]!,
                            ),
                            AppTagChip(
                              label: _medicalLabel(
                                station.allowedMedicalCondition,
                              ),
                              color: Colors.orange[100]!,
                            ),
                            AppTagChip(
                              label: 'Unnamed: $unnamedCount',
                              color: Colors.red[100]!,
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

  Color _occupancyChipColor(int occupancy, int capacity) {
    if (capacity <= 0) return Colors.grey;
    final ratio = occupancy / capacity;
    if (ratio >= 1) return Colors.red;
    if (ratio >= 0.8) return Colors.amber;
    return Colors.green;
  }

  Future<void> _openStationDialog(
    BuildContext context,
    WidgetRef ref,
    EvacuationCenter center, {
    Station? station,
  }) async {
    final nameController = TextEditingController(text: station?.name ?? '');
    final capacityController = TextEditingController(
      text: (station?.capacity ?? 0).toString(),
    );
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: capacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacity',
                        prefixIcon: Icon(Icons.people),
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

                    final parsedCapacity = int.tryParse(
                      capacityController.text.trim(),
                    );
                    if (parsedCapacity == null || parsedCapacity < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Capacity must be a non-negative number',
                          ),
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
    final parsedCapacity = int.tryParse(capacityController.text.trim()) ?? 0;

    final stationToSave =
        (station ??
                Station(
                  id: IdService.newId(),
                  name: trimmedName,
                  evacuationCenterId: center.id,
                  capacity: parsedCapacity,
                ))
            .copyWith(
              name: trimmedName,
              capacity: parsedCapacity,
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

  Future<void> _openStationArrivalsSheet(
    BuildContext context,
    WidgetRef ref,
    Station station,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, controller) {
            final unnamedAsync = ref.watch(
              unnamedEvacueesByStationProvider(station.id),
            );

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${station.name} - Unnamed Arrivals',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: unnamedAsync.when(
                      data: (evacuees) {
                        if (evacuees.isEmpty) {
                          return const Center(
                            child: Text('No unnamed evacuees in this station.'),
                          );
                        }

                        return ListView.builder(
                          controller: controller,
                          itemCount: evacuees.length,
                          itemBuilder: (context, index) {
                            final evacuee = evacuees[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text('Arrival ${index + 1}'),
                                subtitle: Text(
                                  '${_ageLabel(evacuee.ageGroup)} | ${_medicalLabel(evacuee.medicalCondition)}',
                                ),
                                trailing: TextButton(
                                  onPressed: () async {
                                    final name = await _promptName(
                                      context,
                                      'Register Name',
                                    );
                                    if (name == null || name.trim().isEmpty) {
                                      return;
                                    }

                                    final db = ref.read(
                                      databaseServiceProvider,
                                    );
                                    await db.registerEvacueeName(
                                      evacuee.id,
                                      name,
                                    );
                                    ref.invalidate(
                                      unnamedEvacueesByStationProvider(
                                        station.id,
                                      ),
                                    );
                                    ref.invalidate(allEvacueesProvider);
                                  },
                                  child: const Text('Register Name'),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _promptName(BuildContext context, String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter evacuee name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    return result;
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
