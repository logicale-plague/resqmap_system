import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/utils/id_service.dart';
import 'package:kalig_onan_evac_system/core/widgets/app_list_item_card.dart';
import 'package:kalig_onan_evac_system/core/widgets/app_state/app_error_state.dart';
import 'package:kalig_onan_evac_system/core/widgets/app_state/app_loading_state.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/presentation/providers/evacuee_providers.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/presentation/providers/station_providers.dart';
import 'package:kalig_onan_evac_system/features/staff/sync/application/sync_service.dart';

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
      // localRef.invalidate(currentCenterProvider);
      localRef.invalidate(eligibleStationsProvider);
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
  final editingIndexNotifier = ValueNotifier<int?>(-1);

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

                          return ValueListenableBuilder<int?>(
                            valueListenable: editingIndexNotifier,
                            builder: (context, editingIndex, _) {
                              return ListView.builder(
                                controller: controller,
                                itemCount: evacuees.length,
                                itemBuilder: (context, index) {
                                  final evacuee = evacuees[index];

                                  if (editingIndex == index) {
                                    // Inline edit mode
                                    return _InlineRenameCard(
                                      evacuee: evacuee,
                                      index: index,
                                      onSave: (name) async {
                                        if (name.trim().isEmpty) {
                                          editingIndexNotifier.value = -1;
                                          return;
                                        }

                                        try {
                                          final dbService = sheetRef.read(
                                            databaseServiceProvider,
                                          );
                                          final db = await dbService.database;
                                          await db.update(
                                            'evacuees',
                                            {'name': name.trim(), 'synced': 0},
                                            where: 'id = ?',
                                            whereArgs: [evacuee.id],
                                          );
                                          if (context.mounted) {
                                            // Invalidate provider to refresh list with updated data
                                            sheetRef.invalidate(
                                              unnamedEvacueesByStationProvider(
                                                station.id,
                                              ),
                                            );
                                            // Trigger sync to upload renamed evacuee to remote
                                            final syncService = sheetRef.read(
                                              syncServiceProvider,
                                            );
                                            unawaited(syncService.syncNow());
                                            editingIndexNotifier.value = -1;
                                          }
                                        } catch (e, stackTrace) {
                                          debugPrint(
                                            'Rename evacuee failed: $e\n$stackTrace',
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Error updating: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      onCancel: () {
                                        editingIndexNotifier.value = -1;
                                      },
                                    );
                                  }

                                  // Normal display mode
                                  return AppListItemCard(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    title: Text('Arrival ${index + 1}'),
                                    subtitle: Text(
                                      '${ageLabel(evacuee.ageGroup)} | ${medicalLabel(evacuee.medicalCondition)}',
                                    ),
                                    trailing: TextButton(
                                      onPressed: () {
                                        editingIndexNotifier.value = index;
                                      },
                                      child: const Text('Register Name'),
                                    ),
                                  );
                                },
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

class _InlineRenameCard extends StatefulWidget {
  final Evacuee evacuee;
  final int index;
  final Function(String name) onSave;
  final VoidCallback onCancel;

  const _InlineRenameCard({
    required this.evacuee,
    required this.index,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_InlineRenameCard> createState() => _InlineRenameCardState();
}

class _InlineRenameCardState extends State<_InlineRenameCard> {
  late final TextEditingController controller;
  late final FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    focusNode = FocusNode();
    // Auto-focus the input field
    Future.microtask(() {
      FocusScope.of(context).requestFocus(focusNode);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppListItemCard(
      margin: const EdgeInsets.only(bottom: 8),
      title: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: const InputDecoration(
          hintText: 'Enter evacuee name',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              focusNode.unfocus();
              widget.onCancel();
            },
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              focusNode.unfocus();
              widget.onSave(controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
