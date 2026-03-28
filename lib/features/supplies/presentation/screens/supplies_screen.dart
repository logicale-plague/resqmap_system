import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/indices/models_index.dart';
import 'package:kalig_onan_evac_system/core/indices/provider_index.dart';
import 'package:kalig_onan_evac_system/core/widgets/index.dart';
import 'package:kalig_onan_evac_system/features/supplies/presentation/widgets/supplies_widgets.dart';

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
      body: AsyncDataBuilder<List<Supply>>(
        asyncValue: suppliesAsync,
        builder: (supplies) {
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
              final statusColor = getStockStatusColor(supply.daysRemaining);
              final statusText = getStockStatusText(supply.daysRemaining);
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
                      showUpdateSupplyDialog(context, ref, supply);
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddSupplyDialog(context, ref),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
