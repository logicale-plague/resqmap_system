import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/index.dart';
import '../services/id_service.dart';
import 'widgets/screen_components.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  AgeGroup? _selectedAgeGroup;
  MedicalCondition? _selectedMedicalCondition;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAgeGroup = AgeGroup.adult;
    _selectedMedicalCondition = MedicalCondition.none;
  }

  Future<void> _submitForm() async {
    if (_selectedAgeGroup == null || _selectedMedicalCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final db = ref.read(databaseServiceProvider);
      final center = await db.getCurrentCenter();
      if (center == null) {
        throw Exception('No evacuation center assigned');
      }

      final eligibleStations = await db.getEligibleStations(
        centerId: center.id,
        ageGroup: _selectedAgeGroup!,
        medicalCondition: _selectedMedicalCondition!,
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

      await db.insertEvacuee(evacuee);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Arrival logged. Assigned to ${assignedStation.name}. Register name in Stations screen.',
          ),
        ),
      );

      // Refresh the providers
      ref.invalidate(allEvacueesProvider);
      ref.invalidate(evacueeCountProvider);
      ref.invalidate(unnamedEvacueesByStationProvider(assignedStation.id));

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Evacuee'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Arrival Intake: Select age group and condition. The system will auto-assign a station and create an unnamed evacuee record.',
              ),
            ),
            const SizedBox(height: 28),

            // Age Group Selection
            Text('Age Group *', style: Theme.of(context).textTheme.titleMedium),
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
                  icon: _getAgeGroupIcon(ageGroup),
                  label: ageGroup.name.toUpperCase(),
                  selectedColor: Colors.blue,
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Medical Condition Selection
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

            Text(
              'Station Assignment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            centerAsync.when(
              data: (center) {
                if (center == null ||
                    _selectedAgeGroup == null ||
                    _selectedMedicalCondition == null) {
                  return const Text(
                    'Select age group and medical condition to preview auto-assigned stations.',
                  );
                }

                final eligibleStationsAsync = ref.watch(
                  eligibleStationsProvider((
                    centerId: center.id,
                    ageGroup: _selectedAgeGroup!,
                    medicalCondition: _selectedMedicalCondition!,
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

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                            'Rule: ${_stationLabel(assignedStation)}',
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
                        'LOG ARRIVAL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stationLabel(Station station) {
    final ageLabel = station.allowedAgeGroup?.name ?? 'Any age group';
    final medicalLabel =
        station.allowedMedicalCondition?.name ?? 'Any condition';
    return '${station.name} ($ageLabel / $medicalLabel)';
  }

  Widget _getAgeGroupIcon(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return const Icon(Icons.child_care, size: 36, color: Colors.blue);
      case AgeGroup.adult:
        return const Icon(Icons.person, size: 36, color: Colors.blue);
      case AgeGroup.elderly:
        return const Icon(Icons.elderly, size: 36, color: Colors.blue);
    }
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
