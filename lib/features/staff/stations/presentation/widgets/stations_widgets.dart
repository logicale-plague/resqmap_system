import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/utils/id_service.dart';
import 'package:kalig_onan_evac_system/core/widgets/app_list_item_card.dart';
import 'package:kalig_onan_evac_system/core/widgets/app_state/app_error_state.dart';
import 'package:kalig_onan_evac_system/core/widgets/app_state/app_loading_state.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/presentation/providers/evacuee_providers.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/presentation/providers/station_providers.dart';

import '../../../../../core/indices/models_index.dart';

String ageLabel(AgeGroup? ageGroup) {
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

String medicalLabel(MedicalCondition? medicalCondition) {
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

Color occupancyChipColor(int occupancy, int capacity) {
  if (capacity <= 0) return Colors.grey;
  final ratio = occupancy / capacity;
  if (ratio >= 1) return Colors.red;
  if (ratio >= 0.8) return Colors.amber;
  return Colors.green;
}

Future<void> openStationDialog(
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
  final localRef = ref;

  try {
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
                            child: Text(ageLabel(ageGroup)),
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
                      value: selectedMedical,
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
                            child: Text(medicalLabel(condition)),
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

    final stationRepository = ref.read(stationRepositoryProvider);
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
      await stationRepository.insert(stationToSave);
    } else {
      await stationRepository.update(stationToSave);
    }

    if (context.mounted) {
      localRef.invalidate(stationsByCenterProvider(center.id));
    }
  } finally {
    nameController.dispose();
    capacityController.dispose();
  }
}

Future<void> openStationArrivalsSheet(
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
          return Consumer(
            builder: (context, sheetRef, _) {
              final unnamedAsync = sheetRef.watch(
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
                              child: Text(
                                'No unnamed evacuees in this station.',
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: controller,
                            itemCount: evacuees.length,
                            itemBuilder: (context, index) {
                              final evacuee = evacuees[index];
                              return AppListItemCard(
                                margin: const EdgeInsets.only(bottom: 8),
                                title: Text('Arrival ${index + 1}'),
                                subtitle: Text(
                                  '${ageLabel(evacuee.ageGroup)} | ${medicalLabel(evacuee.medicalCondition)}',
                                ),
                                trailing: TextButton(
                                  onPressed: () async {
                                    final localSheetRef = sheetRef;
                                    final name = await _promptName(
                                      context,
                                      'Register Name',
                                    );
                                    if (name == null || name.trim().isEmpty) {
                                      return;
                                    }

                                    final evacueeRepository = localSheetRef
                                        .read(evacueeRepositoryProvider);
                                    await evacueeRepository.update(
                                      evacuee.copyWith(name: name.trim()),
                                    );
                                    if (context.mounted) {
                                      localSheetRef.invalidate(
                                        unnamedEvacueesByStationProvider(
                                          station.id,
                                        ),
                                      );
                                      localSheetRef.invalidate(
                                        allEvacueesProvider,
                                      );
                                    }
                                  },
                                  child: const Text('Register Name'),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const AppLoadingState(),
                        error: (err, stack) =>
                            AppErrorState(error: err, stackTrace: stack),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

Future<String?> _promptName(BuildContext context, String title) async {
  final controller = TextEditingController();
  try {
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
  } finally {
    controller.dispose();
  }
}

Future<void> openConfirmDelete(
  BuildContext context,
  WidgetRef ref,
  Station station,
) async {
  final localRef = ref;
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

  final stationRepository = localRef.read(stationRepositoryProvider);
  await stationRepository.delete(station);

  if (context.mounted) {
    localRef.invalidate(stationsByCenterProvider(station.evacuationCenterId));
    localRef.invalidate(allEvacueesProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Station deleted')));
  }
}
