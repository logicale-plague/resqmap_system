import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/indices/models_index.dart';
import 'package:kalig_onan_evac_system/core/indices/provider_index.dart';
import 'package:kalig_onan_evac_system/core/utils/id_service.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/presentation/widgets/evacuees_widgets.dart';
import 'package:kalig_onan_evac_system/core/widgets/index.dart';

enum _AssignmentMode { autoAssignNew, assignFloating }

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  AgeGroup? _selectedAgeGroup;
  MedicalCondition? _selectedMedicalCondition;
  _AssignmentMode _assignmentMode = _AssignmentMode.autoAssignNew;
  String? _selectedFloatingEvacueeId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAgeGroup = AgeGroup.adult;
    _selectedMedicalCondition = MedicalCondition.none;
  }

  Future<void> _submitForm() async {
    if (_assignmentMode == _AssignmentMode.autoAssignNew &&
        (_selectedAgeGroup == null || _selectedMedicalCondition == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final evacueeRepository = ref.read(evacueeRepositoryProvider);
      final center = await ref.read(currentCenterProvider.future);
      if (center == null) {
        throw Exception('No evacuation center assigned');
      }

      if (_assignmentMode == _AssignmentMode.autoAssignNew) {
        final eligibilityParams = (
          centerId: center.id,
          ageGroup: _selectedAgeGroup!,
          medicalCondition: _selectedMedicalCondition!,
        );

        final eligibleStations = await ref.refresh(
          eligibleStationsProvider(eligibilityParams).future,
        );

        if (eligibleStations.isEmpty) {
          throw Exception('No eligible station available for this evacuee');
        }

        final assignedStation = eligibleStations.first;

        final evacuee = Evacuee(
          id: IdService.newId(),
          name: null,
          stationId: assignedStation.id,
          ageGroup: _selectedAgeGroup!,
          medicalCondition: _selectedMedicalCondition!,
          registeredAt: DateTime.now(),
          synced: false,
        );

        await evacueeRepository.insert(evacuee);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Arrival logged. Assigned to ${assignedStation.name}. Register name in Stations screen.',
            ),
          ),
        );

        ref.invalidate(allEvacueesProvider);
        ref.invalidate(evacueeCountProvider);
        ref.invalidate(evacueesByCenterProvider(center.id));
        ref.invalidate(evacueeCountByCenterProvider(center.id));
        ref.invalidate(currentCenterProvider);
        ref.invalidate(unnamedEvacueesByStationProvider(assignedStation.id));
        ref.invalidate(eligibleStationsProvider(eligibilityParams));
      } else {
        final floatingEvacuees = await ref.read(allEvacueesProvider.future);
        final floating = floatingEvacuees.where((ev) => ev.stationId == null);
        if (floating.isEmpty) {
          throw Exception('No unassigned evacuees available for assignment.');
        }

        final selectedEvacuee = floating.firstWhere(
          (ev) => ev.id == _selectedFloatingEvacueeId,
          orElse: () => floating.first,
        );

        final eligibilityParams = (
          centerId: center.id,
          ageGroup: selectedEvacuee.ageGroup,
          medicalCondition: selectedEvacuee.medicalCondition,
        );

        final eligibleStations = await ref.refresh(
          eligibleStationsProvider(eligibilityParams).future,
        );
        if (eligibleStations.isEmpty) {
          throw Exception(
            'No eligible station available in this center for the selected unassigned evacuee.',
          );
        }

        final assignedStation = eligibleStations.first;
        await evacueeRepository.update(
          selectedEvacuee.copyWith(
            stationId: assignedStation.id,
            synced: false,
          ),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assigned evacuee to ${assignedStation.name}.'),
          ),
        );

        ref.invalidate(allEvacueesProvider);
        ref.invalidate(evacueesByCenterProvider(center.id));
        ref.invalidate(evacueeCountByCenterProvider(center.id));
        ref.invalidate(evacueeCountProvider);
        ref.invalidate(currentCenterProvider);
        ref.invalidate(unnamedEvacueesByStationProvider(assignedStation.id));
        ref.invalidate(eligibleStationsProvider(eligibilityParams));
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final centerAsync = ref.watch(currentCenterProvider);
    final floatingEvacueesAsync = ref.watch(allEvacueesProvider);
    final floatingById = <String, Evacuee>{
      for (final evacuee in (floatingEvacueesAsync.value ?? const <Evacuee>[]))
        if (evacuee.stationId == null) evacuee.id: evacuee,
    };
    final floatingEvacuees = floatingById.values.toList(growable: false)
      ..sort((a, b) {
        final aLabel = (a.name?.trim().isNotEmpty ?? false)
            ? a.name!.trim().toLowerCase()
            : a.id;
        final bLabel = (b.name?.trim().isNotEmpty ?? false)
            ? b.name!.trim().toLowerCase()
            : b.id;
        return aLabel.compareTo(bLabel);
      });

    final selectedFloatingValue =
        floatingById.containsKey(_selectedFloatingEvacueeId)
        ? _selectedFloatingEvacueeId
        : null;

    if (selectedFloatingValue == null && floatingEvacuees.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedFloatingEvacueeId = floatingEvacuees.first.id;
        });
      });
    }

    final selectedFloatingEvacuee = floatingEvacuees.where(
      (evacuee) => evacuee.id == _selectedFloatingEvacueeId,
    );
    final floatingTarget = selectedFloatingEvacuee.isEmpty
        ? null
        : selectedFloatingEvacuee.first;

    return Scaffold(
      appBar: buildScreenAppBar(title: 'Register Evacuee'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoContainer.info(
              padding: const EdgeInsets.all(12),
              child: Text(
                _assignmentMode == _AssignmentMode.autoAssignNew
                    ? 'Arrival Intake: Select age group and condition. The system will auto-assign a station and create an unnamed evacuee record.'
                    : 'Unassigned Evacuee Assignment: Select an unassigned evacuee and assign them to an eligible station in the current center.',
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'Assignment Flow',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<_AssignmentMode>(
              segments: const [
                ButtonSegment<_AssignmentMode>(
                  value: _AssignmentMode.autoAssignNew,
                  label: Text('Auto-Assign New'),
                  icon: Icon(Icons.add_circle_outline),
                ),
                ButtonSegment<_AssignmentMode>(
                  value: _AssignmentMode.assignFloating,
                  label: Text('Assign Unassigned'),
                  icon: Icon(Icons.swap_horiz),
                ),
              ],
              selected: {_assignmentMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _assignmentMode = selection.first;
                });
              },
            ),
            const SizedBox(height: 20),

            if (_assignmentMode == _AssignmentMode.autoAssignNew) ...[
              Text(
                'Age Group *',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: AgeGroup.values.map((ageGroup) {
                  final isSelected = _selectedAgeGroup == ageGroup;
                  return SelectableOptionCard(
                    isSelected: isSelected,
                    onTap: () => setState(() {
                      _selectedAgeGroup = ageGroup;
                    }),
                    icon: getAgeGroupIcon(ageGroup),
                    label: ageGroup.name.toUpperCase(),
                    selectedColor: Colors.blue,
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Text(
                'Medical Condition *',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: MedicalCondition.values.map((condition) {
                  final isSelected = _selectedMedicalCondition == condition;
                  return SelectableOptionCard(
                    isSelected: isSelected,
                    onTap: () => setState(() {
                      _selectedMedicalCondition = condition;
                    }),
                    icon: _getMedicalConditionIcon(condition),
                    label: condition.name.toUpperCase(),
                    selectedColor: Colors.orange,
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
            ] else ...[
              Text(
                'Unassigned Evacuee *',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (floatingEvacueesAsync.isLoading)
                const LinearProgressIndicator()
              else if (floatingEvacuees.isEmpty)
                const Text('No unassigned evacuees available.')
              else
                DropdownButtonFormField<String>(
                  value: selectedFloatingValue,
                  decoration: const InputDecoration(
                    labelText: 'Select Unassigned Evacuee',
                    prefixIcon: Icon(Icons.person_search),
                  ),
                  items: [
                    for (final evacuee in floatingEvacuees)
                      DropdownMenuItem<String>(
                        value: evacuee.id,
                        child: Text(
                          '${evacuee.name?.isNotEmpty == true ? evacuee.name : 'ID: ${evacuee.id.substring(0, 8)}'} (${getAgeGroupDisplay(evacuee.ageGroup)} / ${getMedicalConditionDisplay(evacuee.medicalCondition)})',
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFloatingEvacueeId = value;
                    });
                  },
                ),
              const SizedBox(height: 20),
              if (floatingTarget != null)
                InfoContainer.info(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Selected: ${floatingTarget.name?.isNotEmpty == true ? floatingTarget.name : 'ID: ${floatingTarget.id.substring(0, 8)}'}\nAge: ${getAgeGroupDisplay(floatingTarget.ageGroup)} | Condition: ${getMedicalConditionDisplay(floatingTarget.medicalCondition)}',
                  ),
                ),
              const SizedBox(height: 16),
            ],

            Text(
              'Station Assignment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            centerAsync.when(
              data: (center) {
                if (center == null) {
                  return const Text('No current evacuation center selected.');
                }

                final ageGroup =
                    _assignmentMode == _AssignmentMode.autoAssignNew
                    ? _selectedAgeGroup
                    : floatingTarget?.ageGroup;
                final medicalCondition =
                    _assignmentMode == _AssignmentMode.autoAssignNew
                    ? _selectedMedicalCondition
                    : floatingTarget?.medicalCondition;

                if (ageGroup == null || medicalCondition == null) {
                  return Text(
                    _assignmentMode == _AssignmentMode.autoAssignNew
                        ? 'Select age group and medical condition to preview auto-assigned stations.'
                        : 'Select an unassigned evacuee to preview assignment.',
                  );
                }

                final eligibleStationsAsync = ref.watch(
                  eligibleStationsProvider((
                    centerId: center.id,
                    ageGroup: ageGroup,
                    medicalCondition: medicalCondition,
                  )),
                );

                return eligibleStationsAsync.when(
                  data: (stations) {
                    if (stations.isEmpty) {
                      return const Text(
                        'No station can accept this age group and medical condition.',
                      );
                    }

                    final assignedStation = stations.first;

                    return InfoContainer.success(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Auto-assigned station:',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(assignedStation.name),
                          const SizedBox(height: 6),
                          Text(
                            'Rule: ${getStationLabel(assignedStation)}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (err, stack) => Text(
                    'Error loading stations: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (err, stack) => Text(
                'Error loading center: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'CONFIRM ASSIGNMENT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }

  Widget _getMedicalConditionIcon(MedicalCondition condition) {
    final isSelected = _selectedMedicalCondition == condition;
    switch (condition) {
      case MedicalCondition.none:
        return Icon(
          Icons.favorite,
          size: 36,
          color: isSelected ? Colors.white : Colors.green,
        );
      case MedicalCondition.minor:
        return Icon(
          Icons.health_and_safety,
          size: 36,
          color: isSelected ? Colors.white : Colors.orange,
        );
      case MedicalCondition.serious:
        return Icon(
          Icons.local_hospital,
          size: 36,
          color: isSelected ? Colors.white : Colors.red,
        );
    }
  }
}
