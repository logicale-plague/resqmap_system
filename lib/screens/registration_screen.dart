import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/index.dart';
import '../services/id_service.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _nameController = TextEditingController();

  AgeGroup? _selectedAgeGroup;
  MedicalCondition? _selectedMedicalCondition;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAgeGroup = AgeGroup.adult;
    _selectedMedicalCondition = MedicalCondition.none;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
      final evacuee = Evacuee(
        id: IdService.newId(),
        name: _nameController.text.isEmpty ? null : _nameController.text,
        ageGroup: _selectedAgeGroup!,
        medicalCondition: _selectedMedicalCondition!,
        registeredAt: DateTime.now(),
        synced: false,
      );

      await db.insertEvacuee(evacuee);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evacuee registered successfully')),
      );

      // Refresh the providers
      ref.invalidate(allEvacueesProvider);
      ref.invalidate(evacueeCountProvider);

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
            // Name Field
            Text(
              'Name (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter evacuee name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
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
                return GestureDetector(
                  onTap: () => setState(() => _selectedAgeGroup = ageGroup),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _getAgeGroupIcon(ageGroup),
                        const SizedBox(height: 8),
                        Text(
                          ageGroup.name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
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
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedMedicalCondition = condition),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _getMedicalConditionIcon(condition),
                        const SizedBox(height: 8),
                        Text(
                          condition.name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
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
                        'REGISTER',
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
