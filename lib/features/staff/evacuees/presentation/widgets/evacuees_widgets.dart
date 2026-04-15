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
) async {
  final nameController = TextEditingController(text: evacuee.name ?? '');
  var controllerDisposed = false;

  Future<void> disposeControllerAfterDialog() async {
    if (controllerDisposed) {
      return;
    }
    controllerDisposed = true;
    await Future<void>.delayed(Duration.zero);
    nameController.dispose();
  }

  String _selectedGender = _normalizeGender(evacuee.gender);
  AgeGroup selectedAgeGroup = evacuee.ageGroup;
  MedicalCondition selectedCondition = evacuee.medicalCondition;
  bool isActive = evacuee.active;
  String? selectedStationId = evacuee.stationId;
  bool isLoadingEligibleStations = false;
  List<Station> eligibleStations = await _loadEligibleStationsForAssignment(
    ref: ref,
    evacuee: evacuee,
    allStations: stations,
    centerId: centerId,
    ageGroup: selectedAgeGroup,
    medicalCondition: selectedCondition,
  );

  if (selectedStationId != null &&
      !eligibleStations.any((station) => station.id == selectedStationId)) {
    selectedStationId = null;
  }

  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
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
                  DropdownButtonFormField(
                    initialValue: _selectedGender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: [
                      const DropdownMenuItem(
                        value: 'Male',
                        child: Text('Male'),
                      ),
                      const DropdownMenuItem(
                        value: 'Female',
                        child: Text('Female'),
                      ),
                      const DropdownMenuItem(
                        value: 'Other',
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        _selectedGender = _normalizeGender(value);
                      });
                    },
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
                    onChanged: (value) async {
                      if (value == null) return;
                      setDialogState(() {
                        selectedAgeGroup = value;
                        isLoadingEligibleStations = true;
                      });

                      final refreshedEligibleStations =
                          await _loadEligibleStationsForAssignment(
                            ref: ref,
                            evacuee: evacuee,
                            allStations: stations,
                            centerId: centerId,
                            ageGroup: selectedAgeGroup,
                            medicalCondition: selectedCondition,
                          );

                      if (!dialogContext.mounted) return;

                      setDialogState(() {
                        eligibleStations = refreshedEligibleStations;
                        isLoadingEligibleStations = false;
                        if (selectedStationId != null &&
                            !eligibleStations.any(
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
                    onChanged: (value) async {
                      if (value == null) return;
                      setDialogState(() {
                        selectedCondition = value;
                        isLoadingEligibleStations = true;
                      });

                      final refreshedEligibleStations =
                          await _loadEligibleStationsForAssignment(
                            ref: ref,
                            evacuee: evacuee,
                            allStations: stations,
                            centerId: centerId,
                            ageGroup: selectedAgeGroup,
                            medicalCondition: selectedCondition,
                          );

                      if (!dialogContext.mounted) return;

                      setDialogState(() {
                        eligibleStations = refreshedEligibleStations;
                        isLoadingEligibleStations = false;
                        if (selectedStationId != null &&
                            !eligibleStations.any(
                              (station) => station.id == selectedStationId,
                            )) {
                          selectedStationId = null;
                        }
                      });
                    },
                  ),
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
                  if (isLoadingEligibleStations)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
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
  );

  if (shouldSave != true) {
    await disposeControllerAfterDialog();
    return;
  }

  try {
    final updatedEvacuee = evacuee.copyWith(
      name: nameController.text.trim().isEmpty
          ? null
          : nameController.text.trim(),
      ageGroup: selectedAgeGroup,
      gender: _selectedGender,
      medicalCondition: selectedCondition,
      active: isActive,
      stationId: selectedStationId,
      clearStationId: selectedStationId == null,
    );

    await ref.read(evacueeRepositoryProvider).update(updatedEvacuee);

    if (!context.mounted) {
      await disposeControllerAfterDialog();
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
      await disposeControllerAfterDialog();
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Failed to update evacuee: $e')));
  } finally {
    await disposeControllerAfterDialog();
  }
}

Future<List<Station>> _loadEligibleStationsForAssignment({
  required WidgetRef ref,
  required Evacuee evacuee,
  required List<Station> allStations,
  required String? centerId,
  required AgeGroup ageGroup,
  required MedicalCondition medicalCondition,
}) async {
  final eligibleStations = centerId == null
      ? allStations
            .where(
              (station) => _isStationEligibleForEvacuee(
                station,
                ageGroup,
                medicalCondition,
              ),
            )
            .toList()
      : await ref
            .read(stationRepositoryProvider)
            .getEligible(centerId, ageGroup, medicalCondition);

  final currentStationId = evacuee.stationId;
  if (currentStationId != null) {
    final currentMatches = allStations.where(
      (station) => station.id == currentStationId,
    );
    if (currentMatches.isNotEmpty) {
      final currentStation = currentMatches.first;
      final matchesRules = _isStationEligibleForEvacuee(
        currentStation,
        ageGroup,
        medicalCondition,
      );
      final alreadyIncluded = eligibleStations.any(
        (station) => station.id == currentStation.id,
      );
      if (matchesRules && !alreadyIncluded) {
        eligibleStations.add(currentStation);
      }
    }
  }

  eligibleStations.sort((a, b) => a.name.compareTo(b.name));
  return eligibleStations;
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

String _normalizeGender(String? gender) {
  switch (gender) {
    case 'Male':
    case 'Female':
    case 'Other':
      return gender!;
    default:
      return 'Other';
  }
}
