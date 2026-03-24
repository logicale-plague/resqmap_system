import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResourceMonitoringScreen extends ConsumerWidget {
  const ResourceMonitoringScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resource Monitoring'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Resource Monitoring',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Monitor medicine supplies and capacity across all centers',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Filter/Sort Options
            _FilterBar(),
            const SizedBox(height: 16),

            // Resource List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              itemBuilder: (context, index) {
                return _ResourceMonitoringCard(
                  centerName: 'Evacuation Center ${index + 1}',
                  centerLocation:
                      'Zone ${String.fromCharCode(65 + (index % 4))}',
                  totalCapacity: 200 + (index * 50),
                  currentOccupancy: 120 + (index * 30),
                  medicineStatus: _getMedicineStatus(index),
                  medicineLevel: _getMedicineLevel(index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getMedicineStatus(int index) {
    final statuses = [
      'Low',
      'Medium',
      'Low',
      'High',
      'Critical',
      'Medium',
      'Low',
      'High',
    ];
    return statuses[index];
  }

  double _getMedicineLevel(int index) {
    final levels = [0.25, 0.60, 0.30, 0.95, 0.10, 0.70, 0.35, 0.85];
    return levels[index];
  }
}

class _FilterBar extends StatefulWidget {
  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedFilter == 'All',
                  onSelected: () => setState(() => _selectedFilter = 'All'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Critical',
                  isSelected: _selectedFilter == 'Critical',
                  onSelected: () =>
                      setState(() => _selectedFilter = 'Critical'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Low Stock',
                  isSelected: _selectedFilter == 'Low Stock',
                  onSelected: () =>
                      setState(() => _selectedFilter = 'Low Stock'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Overcrowded',
                  isSelected: _selectedFilter == 'Overcrowded',
                  onSelected: () =>
                      setState(() => _selectedFilter = 'Overcrowded'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.blue.withOpacity(0.5),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _ResourceMonitoringCard extends StatelessWidget {
  final String centerName;
  final String centerLocation;
  final int totalCapacity;
  final int currentOccupancy;
  final String medicineStatus;
  final double medicineLevel;

  const _ResourceMonitoringCard({
    required this.centerName,
    required this.centerLocation,
    required this.totalCapacity,
    required this.currentOccupancy,
    required this.medicineStatus,
    required this.medicineLevel,
  });

  Color _getStatusColor() {
    switch (medicineStatus) {
      case 'Critical':
        return Colors.red;
      case 'Low':
        return Colors.orange;
      case 'Medium':
        return Colors.yellow[700]!;
      case 'High':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool _isOvercrowded() {
    return (currentOccupancy / totalCapacity) > 0.80;
  }

  @override
  Widget build(BuildContext context) {
    final capacityPercentage = (currentOccupancy / totalCapacity);
    final capacityColor = capacityPercentage > 0.80
        ? Colors.red
        : capacityPercentage > 0.60
        ? Colors.orange
        : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with center name and alerts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        centerName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        centerLocation,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isOvercrowded())
                  Chip(
                    label: const Text('Overcrowded'),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Capacity Section
            Text(
              'Capacity',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: capacityPercentage,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(capacityColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(capacityPercentage * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$currentOccupancy / $totalCapacity evacuees',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),

            // Medicine Supply Section
            Text(
              'Medicine Supply',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: medicineLevel,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    medicineStatus,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: View details
                    },
                    icon: const Icon(Icons.info),
                    label: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Transfer supplies
                    },
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('Transfer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
