import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/index.dart';
import '../services/id_service.dart';

class SuppliesScreen extends ConsumerWidget {
  const SuppliesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliesAsync = ref.watch(allSuppliesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Supplies'),
        backgroundColor: Colors.indigo,
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No supplies tracked',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: supplies.length,
            itemBuilder: (context, index) {
              final supply = supplies[index];
              final statusColor = _getStockStatusColor(supply.daysRemaining);
              final statusText = _getStockStatusText(supply.daysRemaining);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${supply.daysRemaining} days remaining',
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
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSupplyDialog(context, ref),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStockStatusColor(int daysRemaining) {
    if (daysRemaining < 1) return Colors.red;
    if (daysRemaining < 7) return Colors.orange;
    return Colors.green;
  }

  String _getStockStatusText(int daysRemaining) {
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

              final db = ref.read(databaseServiceProvider);
              final center = await db.getCurrentCenter();
              if (center == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No evacuation center found for this device'),
                  ),
                );
                return;
              }
              final supply = Supply(
                id: IdService.newId(),
                evacuationCenterId: center.id,
                name: nameController.text,
                currentStock: int.parse(stockController.text),
                usageRatePerDay: int.parse(usageController.text),
                lastRestocked: DateTime.now(),
              );

              await db.insertSupply(supply);
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

              final db = ref.read(databaseServiceProvider);
              await db.updateSupplyStock(
                supply.id,
                int.parse(stockController.text),
              );
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
