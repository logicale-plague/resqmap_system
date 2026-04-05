import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';

class EvacInfoBotsheet extends ConsumerWidget {
  final EvacuationCenter center;
  const EvacInfoBotsheet({super.key, required this.center});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 1. Calculate safe capacity metrics
    final double capacityPercentage = center.totalCapacity > 0
        ? ((center.totalCapacity - center.availableSpaces) /
                  center.totalCapacity)
              .clamp(0.0, 1.0)
        : 0.0;

    // 2. Dynamic Colors for instant visual feedback
    final bool isOperational = center.status == CenterStatus.operational;
    final Color statusColor = isOperational
        ? Colors.green.shade700
        : colorScheme.error;

    final Color capacityColor = capacityPercentage >= 0.95
        ? colorScheme
              .error // Almost full/Full -> Red
        : capacityPercentage >= 0.75
        ? Colors
              .orange
              .shade700 // Getting packed -> Orange
        : Colors.green.shade700; // Plenty of space -> Green

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Name & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  center.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withAlpha(50)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOperational
                          ? Icons.check_circle
                          : Icons.warning_rounded,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOperational ? 'OPERATIONAL' : 'CLOSED',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: Colors.black),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  center.fullAddress.isNotEmpty
                      ? center.fullAddress
                      : 'Address not available',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Capacity Visualizer
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Capacity",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "${center.availableSpaces} spots left",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: capacityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: capacityPercentage,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(capacityColor),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Total capacity: ${center.totalCapacity}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () {
                // TODO: Wire up routing/directions
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.directions_outlined),
              label: const Text(
                "Get Directions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
