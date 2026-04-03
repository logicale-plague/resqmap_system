import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/indices/provider_index.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/domain/evacuee.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/domain/station.dart';

String getAgeGroupDisplay(AgeGroup ageGroup) {
  switch (ageGroup) {
    case AgeGroup.child:
      return 'Child';
    case AgeGroup.adult:
      return 'Adult';
    case AgeGroup.elderly:
      return 'Elderly';
  }
}

String getMedicalConditionDisplay(MedicalCondition condition) {
  switch (condition) {
    case MedicalCondition.none:
      return 'None';
    case MedicalCondition.minor:
      return 'Minor';
    case MedicalCondition.serious:
      return 'Serious';
  }
}

Color getMedicalConditionColor(MedicalCondition condition) {
  switch (condition) {
    case MedicalCondition.none:
      return Colors.green;
    case MedicalCondition.minor:
      return Colors.orange;
    case MedicalCondition.serious:
      return Colors.red;
  }
}

String getStationLabel(Station station) {
  final ageLabel = station.allowedAgeGroup != null
      ? getAgeGroupDisplay(station.allowedAgeGroup!)
      : 'Any age group';
  final medicalLabel = station.allowedMedicalCondition != null
      ? getMedicalConditionDisplay(station.allowedMedicalCondition!)
      : 'Any condition';
  return '${station.name} ($ageLabel / $medicalLabel)';
}

Widget getAgeGroupIcon(AgeGroup ageGroup) {
  switch (ageGroup) {
    case AgeGroup.child:
      return const Icon(Icons.child_care, size: 36, color: Colors.blue);
    case AgeGroup.adult:
      return const Icon(Icons.person, size: 36, color: Colors.blue);
    case AgeGroup.elderly:
      return const Icon(Icons.elderly, size: 36, color: Colors.blue);
  }
}

Future<void> openEvacueeDetailsDialog(
  BuildContext context,
  WidgetRef ref,
  Evacuee evacuee,
  List<Station> stations,
  String? centerId,
) {
  final nameController = TextEditingController(text: evacuee.name ?? '');
  AgeGroup selectedAgeGroup = evacuee.ageGroup;
  MedicalCondition selectedCondition = evacuee.medicalCondition;
  bool isActive = evacuee.active;
  String? selectedStationId = evacuee.stationId;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final eligibleStations = stations
              .where(
                (station) => _isStationEligibleForEvacuee(
                  station,
                  selectedAgeGroup,
                  selectedCondition,
                ),
              )
              .toList();

          return AlertDialog(
            title: const Text('Edit Evacuee'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter evacuee name',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AgeGroup>(
                    initialValue: selectedAgeGroup,
                    decoration: const InputDecoration(labelText: 'Age Group'),
                    items: AgeGroup.values
                        .map(
                          (value) => DropdownMenuItem<AgeGroup>(
                            value: value,
                            child: Text(getAgeGroupDisplay(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedAgeGroup = value;
                        final updatedEligibleStations = stations.where(
                          (station) => _isStationEligibleForEvacuee(
                            station,
                            selectedAgeGroup,
                            selectedCondition,
                          ),
                        );
                        if (selectedStationId != null &&
                            !updatedEligibleStations.any(
                              (station) => station.id == selectedStationId,
                            )) {
                          selectedStationId = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MedicalCondition>(
                    initialValue: selectedCondition,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: MedicalCondition.values
                        .map(
                          (value) => DropdownMenuItem<MedicalCondition>(
                            value: value,
                            child: Text(getMedicalConditionDisplay(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedCondition = value;
                        final updatedEligibleStations = stations.where(
                          (station) => _isStationEligibleForEvacuee(
                            station,
                            selectedAgeGroup,
                            selectedCondition,
                          ),
                        );
                        if (selectedStationId != null &&
                            !updatedEligibleStations.any(
                              (station) => station.id == selectedStationId,
                            )) {
                          selectedStationId = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<bool>(
                    initialValue: isActive,
                    decoration: const InputDecoration(labelText: 'Record'),
                    items: const [
                      DropdownMenuItem<bool>(
                        value: true,
                        child: Text('Active'),
                      ),
                      DropdownMenuItem<bool>(
                        value: false,
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => isActive = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedStationId,
                    decoration: const InputDecoration(
                      labelText: 'Room Assignment',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...eligibleStations.map(
                        (station) => DropdownMenuItem<String?>(
                          value: station.id,
                          child: Text(station.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedStationId = value);
                    },
                  ),
                  if (eligibleStations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'No compatible room is available for this age group and status.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  ).then((shouldSave) async {
    if (shouldSave != true) {
      nameController.dispose();
      return;
    }

    try {
      final updatedEvacuee = evacuee.copyWith(
        name: nameController.text.trim().isEmpty
            ? null
            : nameController.text.trim(),
        ageGroup: selectedAgeGroup,
        medicalCondition: selectedCondition,
        active: isActive,
        stationId: selectedStationId,
      );

      await ref.read(evacueeRepositoryProvider).update(updatedEvacuee);

      if (!context.mounted) {
        nameController.dispose();
        return;
      }

      final affectedStationIds = <String>{
        if (evacuee.stationId != null) evacuee.stationId!,
        if (updatedEvacuee.stationId != null) updatedEvacuee.stationId!,
      };

      ref.invalidate(allEvacueesProvider);
      ref.invalidate(evacueeCountProvider);
      for (final stationId in affectedStationIds) {
        ref.invalidate(unnamedEvacueesByStationProvider(stationId));
        ref.invalidate(evacueeCountByStationProvider(stationId));
      }
      if (centerId != null) {
        ref.invalidate(evacueesByCenterProvider(centerId));
        ref.invalidate(evacueeCountByCenterProvider(centerId));
      }
      ref.invalidate(currentCenterProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evacuee updated successfully')),
      );
    } catch (e) {
      if (!context.mounted) {
        nameController.dispose();
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update evacuee: $e')));
    } finally {
      nameController.dispose();
    }
  });
}

bool _isStationEligibleForEvacuee(
  Station station,
  AgeGroup ageGroup,
  MedicalCondition medicalCondition,
) {
  final matchesAgeGroup =
      station.allowedAgeGroup == null || station.allowedAgeGroup == ageGroup;
  final matchesMedicalCondition =
      station.allowedMedicalCondition == null ||
      station.allowedMedicalCondition == medicalCondition;
  return matchesAgeGroup && matchesMedicalCondition;
}
