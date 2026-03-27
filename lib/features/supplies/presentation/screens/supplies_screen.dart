import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/indices/models_index.dart';
import 'package:kalig_onan_evac_system/core/indices/provider_index.dart';
import 'package:kalig_onan_evac_system/core/utils/id_service.dart';
import 'package:kalig_onan_evac_system/core/widgets/index.dart';

class SuppliesScreen extends ConsumerWidget {
  const SuppliesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliesAsync = ref.watch(allSuppliesProvider);

    return Scaffold(
      appBar: buildScreenAppBar(
        title: 'Medical Supplies',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(allSuppliesProvider),
          ),
        ],
      ),
      body: suppliesAsync.when(
        data: (supplies) {
          if (supplies.isEmpty) {
            return const AppEmptyState(
              icon: Icons.medical_services,
              message: 'No supplies tracked',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: supplies.length,
            itemBuilder: (context, index) {
              final supply = supplies[index];
              final statusColor = _getStockStatusColor(supply.daysRemaining);
              final statusText = _getStockStatusText(supply.daysRemaining);
              final daysRemainingText = supply.daysRemaining == null
                  ? 'Not currently consumed'
                  : '${supply.daysRemaining} days remaining';

              return AppListItemCard(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.medical_services, color: statusColor),
                ),
                title: Text(
                  supply.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stock: ${supply.currentStock} units',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Usage: ${supply.usageRatePerDay} units/day',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (supply.currentStock / 100).clamp(0, 1),
                        minHeight: 6,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysRemainingText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'update') {
                      _showUpdateSupplyDialog(context, ref, supply);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'update',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 12),
                          Text('Update Stock'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const AppLoadingState(),
        error: (err, stack) => AppErrorState(error: err, stackTrace: stack),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSupplyDialog(context, ref),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStockStatusColor(int? daysRemaining) {
    if (daysRemaining == null) return Colors.blueGrey;
    if (daysRemaining < 1) return Colors.red;
    if (daysRemaining < 7) return Colors.orange;
    return Colors.green;
  }

  String _getStockStatusText(int? daysRemaining) {
    if (daysRemaining == null) return 'NOT IN USE';
    if (daysRemaining < 1) return 'CRITICAL';
    if (daysRemaining < 7) return 'LOW';
    return 'ADEQUATE';
  }

  void _showAddSupplyDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final usageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Supply'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Supply Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Current Stock',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Usage Rate (units/day)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  stockController.text.isEmpty ||
                  usageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final supplyRepository = ref.read(supplyRepositoryProvider);
              final center = await ref.read(currentCenterProvider.future);
              if (center == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No evacuation center found for this device'),
                  ),
                );
                return;
              }
              final parsedStock = int.tryParse(stockController.text);
              final parsedUsageRate = int.tryParse(usageController.text);
              if (parsedStock == null || parsedUsageRate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Stock and usage rate must be valid integers',
                    ),
                  ),
                );
                return;
              }
              if (parsedStock < 0 || parsedUsageRate < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Stock and usage rate must be >= 0'),
                  ),
                );
                return;
              }
              final supply = Supply(
                id: IdService.newId(),
                evacuationCenterId: center.id,
                name: nameController.text,
                currentStock: parsedStock,
                usageRatePerDay: parsedUsageRate,
                lastRestocked: DateTime.now(),
              );

              await supplyRepository.insert(supply);
              if (!context.mounted) return;
              Navigator.pop(context);

              ref.invalidate(allSuppliesProvider);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Supply added')));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showUpdateSupplyDialog(
    BuildContext context,
    WidgetRef ref,
    Supply supply,
  ) {
    final stockController = TextEditingController(
      text: supply.currentStock.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Stock'),
        content: TextField(
          controller: stockController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Current Stock',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (stockController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter stock quantity')),
                );
                return;
              }

              final supplyRepository = ref.read(supplyRepositoryProvider);
              final parsedStock = int.tryParse(stockController.text);
              if (parsedStock == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Stock quantity must be a valid integer'),
                  ),
                );
                return;
              }
              if (parsedStock < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stock quantity must be >= 0')),
                );
                return;
              }
              await supplyRepository.updateStock(supply.id, parsedStock);
              if (!context.mounted) return;
              Navigator.pop(context);

              ref.invalidate(allSuppliesProvider);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Stock updated')));
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
