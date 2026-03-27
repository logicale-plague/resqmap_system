import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/utils/id_service.dart';
import 'package:kalig_onan_evac_system/features/centers/presentation/providers/evacuation_center_providers.dart';
import 'package:kalig_onan_evac_system/features/supplies/domain/supply.dart';
import 'package:kalig_onan_evac_system/features/supplies/presentation/providers/supply_providers.dart';

Color getStockStatusColor(int? daysRemaining) {
  if (daysRemaining == null) return Colors.blueGrey;
  if (daysRemaining < 1) return Colors.red;
  if (daysRemaining < 7) return Colors.orange;
  return Colors.green;
}

String getStockStatusText(int? daysRemaining) {
  if (daysRemaining == null) return 'NOT IN USE';
  if (daysRemaining < 1) return 'CRITICAL';
  if (daysRemaining < 7) return 'LOW';
  return 'ADEQUATE';
}

void showAddSupplyDialog(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  final stockController = TextEditingController();
  final usageController = TextEditingController();
  bool isSubmitting = false;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
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
            onPressed: isSubmitting ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    if (isSubmitting) return;

                    if (nameController.text.isEmpty ||
                        stockController.text.isEmpty ||
                        usageController.text.isEmpty) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    final parsedStock = int.tryParse(stockController.text);
                    final parsedUsageRate = int.tryParse(usageController.text);
                    if (parsedStock == null || parsedUsageRate == null) {
                      if (!context.mounted) return;
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
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stock and usage rate must be >= 0'),
                        ),
                      );
                      return;
                    }

                    setDialogState(() => isSubmitting = true);

                    final center = await ref.read(currentCenterProvider.future);
                    if (center == null) {
                      setDialogState(() => isSubmitting = false);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No evacuation center found for this device',
                          ),
                        ),
                      );
                      return;
                    }

                    final supplyRepository = ref.read(supplyRepositoryProvider);
                    final supply = Supply(
                      id: IdService.newId(),
                      evacuationCenterId: center.id,
                      name: nameController.text,
                      currentStock: parsedStock,
                      usageRatePerDay: parsedUsageRate,
                      lastRestocked: DateTime.now(),
                    );

                    try {
                      setDialogState(() => isSubmitting = true);
                      await supplyRepository.insert(supply);
                    } catch (_) {
                      setDialogState(() => isSubmitting = false);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to add supply')),
                      );
                      return;
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ref.invalidate(allSuppliesProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Supply added')),
                    );
                  },
            child: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add'),
          ),
        ],
      ),
    ),
  );
}

void showUpdateSupplyDialog(
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
            final updatedSupply = supply.copyWith(currentStock: parsedStock);
            try {
              await supplyRepository.update(updatedSupply);
            } on StateError {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Supply no longer exists')),
              );
              return;
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update supply stock')),
              );
              return;
            }
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
