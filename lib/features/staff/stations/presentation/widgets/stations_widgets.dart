import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/exceptions/offline_exception.dart';
import 'package:kalig_onan_evac_system/core/utils/id_service.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/presentation/providers/evacuee_providers.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/presentation/providers/station_providers.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/presentation/widgets/station_arrivals_sheet.dart';

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
    final shouldSave = await _showStationDialog(
      context,
      station,
      nameController,
      capacityController,
      selectedAgeGroup: selectedAgeGroup,
      selectedMedical: selectedMedical,
      onAgeGroupChanged: (value) {
        selectedAgeGroup = value;
      },
      onMedicalChanged: (value) {
        selectedMedical = value;
      },
    );

    if (shouldSave != true) return;

    try {
      await _saveStationChanges(
        context,
        localRef,
        center,
        station,
        nameController,
        capacityController,
        selectedAgeGroup,
        selectedMedical,
      );
    } on OfflineException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save station: $e')));
    }
  } finally {
    nameController.dispose();
    capacityController.dispose();
  }
}

Future<bool?> _showStationDialog(
  BuildContext context,
  Station? station,
  TextEditingController nameController,
  TextEditingController capacityController, {
  required AgeGroup? selectedAgeGroup,
  required MedicalCondition? selectedMedical,
  required ValueChanged<AgeGroup?> onAgeGroupChanged,
  required ValueChanged<MedicalCondition?> onMedicalChanged,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(station == null ? 'Add Station' : 'Edit Station'),
            content: _buildStationDialogForm(
              nameController,
              capacityController,
              selectedAgeGroup,
              selectedMedical,
              (value) {
                setDialogState(() {
                  selectedAgeGroup = value;
                });
                onAgeGroupChanged(value);
              },
              (value) {
                setDialogState(() {
                  selectedMedical = value;
                });
                onMedicalChanged(value);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!_validateStationForm(
                    context,
                    nameController,
                    capacityController,
                  )) {
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
}

Widget _buildStationDialogForm(
  TextEditingController nameController,
  TextEditingController capacityController,
  AgeGroup? selectedAgeGroup,
  MedicalCondition? selectedMedical,
  ValueChanged<AgeGroup?> onAgeGroupChanged,
  ValueChanged<MedicalCondition?> onMedicalChanged,
) {
  return SingleChildScrollView(
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
          onChanged: onAgeGroupChanged,
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
          onChanged: onMedicalChanged,
        ),
      ],
    ),
  );
}

bool _validateStationForm(
  BuildContext context,
  TextEditingController nameController,
  TextEditingController capacityController,
) {
  if (nameController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a station name')),
    );
    return false;
  }

  final parsedCapacity = int.tryParse(capacityController.text.trim());
  if (parsedCapacity == null || parsedCapacity < 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Capacity must be a non-negative number')),
    );
    return false;
  }

  return true;
}

Future<void> _saveStationChanges(
  BuildContext context,
  WidgetRef ref,
  EvacuationCenter center,
  Station? station,
  TextEditingController nameController,
  TextEditingController capacityController,
  AgeGroup? selectedAgeGroup,
  MedicalCondition? selectedMedical,
) async {
  final stationRepository = ref.read(stationRepositoryProvider);
  final trimmedName = nameController.text.trim();
  final parsedCapacity = int.tryParse(capacityController.text.trim()) ?? 0;

  final stationToSave = _buildStationToSave(
    station,
    center,
    trimmedName,
    parsedCapacity,
    selectedAgeGroup,
    selectedMedical,
  );

  if (station == null) {
    await stationRepository.insert(stationToSave);
  } else {
    await stationRepository.update(stationToSave);
  }

  if (!context.mounted) {
    return;
  }

  ref.invalidate(stationsByCenterProvider(center.id));
  // ref.invalidate(currentCenterProvider);
  ref.invalidate(eligibleStationsProvider);
}

Station _buildStationToSave(
  Station? station,
  EvacuationCenter center,
  String trimmedName,
  int parsedCapacity,
  AgeGroup? selectedAgeGroup,
  MedicalCondition? selectedMedical,
) {
  return (station ??
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
}

Future<void> openStationArrivalsSheet(
  BuildContext context,
  WidgetRef ref,
  Station station,
) async {
  final editingIdNotifier = ValueNotifier<String?>(null);

  try {
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
            return StationArrivalsSheetContent(
              station: station,
              controller: controller,
              editingIdNotifier: editingIdNotifier,
            );
          },
        );
      },
    );
  } finally {
    editingIdNotifier.dispose();
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
