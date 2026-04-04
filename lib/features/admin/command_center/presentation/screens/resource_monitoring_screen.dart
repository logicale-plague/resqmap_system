import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kalig_onan_evac_system/core/indices/models_index.dart';
import 'package:kalig_onan_evac_system/core/indices/provider_index.dart';

class ResourceMonitoringScreen extends ConsumerStatefulWidget {
  const ResourceMonitoringScreen({super.key});

  @override
  ConsumerState<ResourceMonitoringScreen> createState() =>
      _ResourceMonitoringScreenState();
}

class _ResourceMonitoringScreenState
    extends ConsumerState<ResourceMonitoringScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final centersAsync = ref.watch(allCentersProvider);
    final suppliesAsync = ref.watch(allCenterSuppliesProvider);

    return Scaffold(
      body: centersAsync.when(
        data: (centers) {
          return suppliesAsync.when(
            data: (supplies) {
              final resources = _buildCenterResources(centers, supplies);
              final filteredResources = resources
                  .where(_matchesFilter)
                  .toList(growable: false);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    _FilterBar(
                      selectedFilter: _selectedFilter,
                      onFilterChanged: (filter) =>
                          setState(() => _selectedFilter = filter),
                    ),
                    const SizedBox(height: 16),
                    if (filteredResources.isEmpty)
                      Text(
                        'No evacuation centers match the selected filter.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      Column(
                        children: [
                          for (final resource in filteredResources)
                            _ResourceMonitoringCard(
                              resource: resource,
                              onDetailsPressed: () =>
                                  _openResourceDetails(context, resource),
                              onTransferPressed: () =>
                                  _openTransferDialog(context, resource),
                            ),
                        ],
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Failed to load supplies: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load evacuation centers: $error')),
      ),
    );
  }

  List<_CenterResourceViewModel> _buildCenterResources(
    List<EvacuationCenter> centers,
    List<Supply> supplies,
  ) {
    final suppliesByCenter = <String, List<Supply>>{};

    for (final supply in supplies) {
      suppliesByCenter
          .putIfAbsent(supply.evacuationCenterId, () => <Supply>[])
          .add(supply);
    }

    return centers
        .map((center) {
          final centerSupplies =
              suppliesByCenter[center.id] ?? const <Supply>[];
          final lowStockSupplies = centerSupplies
              .where(
                (supply) => supply.currentStock < (supply.usageRatePerDay * 7),
              )
              .toList(growable: false);
          final medicineMetrics = _buildMedicineMetrics(center, centerSupplies);

          return _CenterResourceViewModel(
            center: center,
            centerSubtitle: 'Status: ${_statusLabel(center.status)}',
            supplies: centerSupplies,
            lowStockSupplies: lowStockSupplies,
            medicineStatus: medicineMetrics.status,
            medicineLevel: medicineMetrics.level,
          );
        })
        .toList(growable: false);
  }

  _MedicineMetrics _buildMedicineMetrics(
    EvacuationCenter center,
    List<Supply> supplies,
  ) {
    if (supplies.isEmpty) {
      return _MedicineMetrics(
        status: center.medicalAvailable ? 'High' : 'Critical',
        level: center.medicalAvailable ? 1.0 : 0.0,
      );
    }

    final levels = supplies
        .map((supply) => _medicineLevelForDaysRemaining(supply.daysRemaining))
        .toList(growable: false);
    final averageLevel =
        levels.reduce((left, right) => left + right) / levels.length;
    final knownDaysRemaining = supplies
        .map((supply) => supply.daysRemaining)
        .whereType<int>()
        .toList(growable: false);

    if (knownDaysRemaining.isEmpty) {
      return _MedicineMetrics(
        status: 'Unknown',
        level: _medicineLevelForDaysRemaining(null),
      );
    }

    final minimumDaysRemaining = knownDaysRemaining.reduce(
      (left, right) => left < right ? left : right,
    );

    if (minimumDaysRemaining <= 2) {
      return _MedicineMetrics(status: 'Critical', level: averageLevel);
    }
    if (minimumDaysRemaining <= 7) {
      return _MedicineMetrics(status: 'Low', level: averageLevel);
    }
    if (minimumDaysRemaining <= 14) {
      return _MedicineMetrics(status: 'Medium', level: averageLevel);
    }
    return _MedicineMetrics(status: 'High', level: averageLevel);
  }

  double _medicineLevelForDaysRemaining(int? daysRemaining) {
    if (daysRemaining == null) return 0.9;
    if (daysRemaining <= 2) return 0.1;
    if (daysRemaining <= 7) return 0.35;
    if (daysRemaining <= 14) return 0.65;
    return 0.9;
  }

  bool _matchesFilter(_CenterResourceViewModel resource) {
    switch (_selectedFilter) {
      case 'Critical':
        return resource.medicineStatus == 'Critical';
      case 'Low Stock':
        return resource.lowStockSupplies.isNotEmpty;
      case 'Overcrowded':
        return resource.isOvercrowded;
      default:
        return true;
    }
  }

  String _statusLabel(CenterStatus status) {
    switch (status) {
      case CenterStatus.operational:
        return 'Operational';
      case CenterStatus.nearCapacity:
        return 'Near Capacity';
      case CenterStatus.atCapacity:
        return 'At Capacity';
      case CenterStatus.closed:
        return 'Closed';
    }
  }

  void _openResourceDetails(
    BuildContext context,
    _CenterResourceViewModel resource,
  ) {
    final center = resource.center;
    final lowStockNames = resource.lowStockSupplies
        .map((supply) => supply.name)
        .toSet()
        .join(', ');

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${center.name} Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resource.centerSubtitle),
            Text(
              'Occupancy: ${center.currentOccupancy} / ${center.totalCapacity} evacuees',
            ),
            Text(
              'Medicine Supply: ${resource.medicineStatus} '
              '(${(resource.medicineLevel * 100).toStringAsFixed(0)}%)',
            ),
            if (lowStockNames.isNotEmpty)
              Text('Low stock items: $lowStockNames'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openTransferDialog(
    BuildContext context,
    _CenterResourceViewModel resource,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Transfer Supplies'),
        content: Text(
          'Initiate a supply transfer to ${resource.center.name}?\n'
          'Current medicine status: ${resource.medicineStatus}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {});
    }
  }
}

class _FilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const _FilterBar({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

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
                  isSelected: selectedFilter == 'All',
                  onSelected: () => onFilterChanged('All'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Critical',
                  isSelected: selectedFilter == 'Critical',
                  onSelected: () => onFilterChanged('Critical'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Low Stock',
                  isSelected: selectedFilter == 'Low Stock',
                  onSelected: () => onFilterChanged('Low Stock'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Overcrowded',
                  isSelected: selectedFilter == 'Overcrowded',
                  onSelected: () => onFilterChanged('Overcrowded'),
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
      selectedColor: Colors.blue.withValues(alpha: 0.5),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _ResourceMonitoringCard extends StatelessWidget {
  final _CenterResourceViewModel resource;
  final VoidCallback? onDetailsPressed;
  final VoidCallback? onTransferPressed;

  const _ResourceMonitoringCard({
    required this.resource,
    this.onDetailsPressed,
    this.onTransferPressed,
  });

  Color _getStatusColor() {
    switch (resource.medicineStatus) {
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
    return resource.isOvercrowded;
  }

  @override
  Widget build(BuildContext context) {
    final center = resource.center;
    final capacityPercentage = center.totalCapacity > 0
        ? (center.currentOccupancy / center.totalCapacity).clamp(0.0, 1.0)
        : 0.0;
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
                        center.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        resource.centerSubtitle,
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
                    backgroundColor: Colors.red.withAlpha(25),
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
              '${center.currentOccupancy} / ${center.totalCapacity} evacuees',
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
                      value: resource.medicineLevel,
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
                    color: _getStatusColor().withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    resource.medicineStatus,
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
                    onPressed: onDetailsPressed,
                    icon: const Icon(Icons.info),
                    label: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTransferPressed,
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

class _CenterResourceViewModel {
  final EvacuationCenter center;
  final String centerSubtitle;
  final List<Supply> supplies;
  final List<Supply> lowStockSupplies;
  final String medicineStatus;
  final double medicineLevel;

  const _CenterResourceViewModel({
    required this.center,
    required this.centerSubtitle,
    required this.supplies,
    required this.lowStockSupplies,
    required this.medicineStatus,
    required this.medicineLevel,
  });

  bool get isOvercrowded {
    return center.totalCapacity > 0 &&
        (center.currentOccupancy / center.totalCapacity) > 0.80;
  }
}

class _MedicineMetrics {
  final String status;
  final double level;

  const _MedicineMetrics({required this.status, required this.level});
}
