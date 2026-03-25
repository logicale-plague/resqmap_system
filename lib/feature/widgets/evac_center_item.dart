import 'package:flutter/material.dart';
import 'package:kalig_onan_evac_system/models/evacuation_center.dart';

class EvacCenterItem extends StatelessWidget {
  final EvacuationCenter center;
  final VoidCallback onTap;

  const EvacCenterItem({super.key, required this.center, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Calculate occupancy percentage for the progress bar
    double occupancyRate = center.totalCapacity > 0
        ? center.currentOccupancy / center.totalCapacity
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withAlpha(200)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name and Medical Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      center.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (center.medicalAvailable)
                    const Tooltip(
                      message: 'Medical Aid Available',
                      child: Icon(
                        Icons.medical_services_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),

              // Subtitle: Address
              Text(
                center.fullAddress ?? 'Address not specified',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Capacity Logic
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${center.currentOccupancy} / ${center.totalCapacity} occupants',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  _StatusBadge(status: center.status),
                ],
              ),
              const SizedBox(height: 8),

              // Visual Capacity Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: occupancyRate,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  // Changes color based on how full it is
                  color: occupancyRate > 0.9
                      ? Colors.orange
                      : Colors.blueAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for a clean Status Tag
class _StatusBadge extends StatelessWidget {
  final CenterStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case CenterStatus.operational:
        color = Colors.green;
        break;
      case CenterStatus.nearCapacity:
        color = Colors.amber;
        break;
      case CenterStatus.atCapacity:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
