import 'package:flutter/material.dart';
import 'package:kalig_onan_evac_system/models/evacuation_center.dart';

class EvacCenterDetailsPage extends StatelessWidget {
  final EvacuationCenter center;

  const EvacCenterDetailsPage({super.key, required this.center});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Immersive Header with Map/Image Placeholder
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                center.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Placeholder for your Map or Center Image
                  Container(color: Colors.blueGrey[900]),
                  const Center(
                    child: Icon(
                      Icons.map_outlined,
                      color: Colors.white24,
                      size: 80,
                    ),
                  ),
                  // Gradient overlay for text readability
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLiveStatusRow(),
                  const SizedBox(height: 24),

                  // Bento-style Information Grid
                  Row(
                    children: [
                      Expanded(
                        child: _infoTile(
                          label: 'Capacity',
                          value:
                              '${center.currentOccupancy}/${center.totalCapacity}',
                          icon: Icons.people_outline,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoTile(
                          label: 'Medical',
                          value: center.medicalAvailable ? 'On-site' : 'None',
                          icon: Icons.health_and_safety_outlined,
                          color: center.medicalAvailable
                              ? Colors.redAccent
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Address Section
                  _sectionHeader('Location Details'),
                  Text(
                    center.fullAddress ?? 'Address details pending...',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {}, // Trigger navigation logic
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text('Get Directions'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildLiveStatusRow() {
    return Row(
      children: [
        // A "Live" pulse indicator for synced data
        if (center.synced)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.circle, color: Colors.green, size: 10),
          ),
        Text(
          'Updated: ${center.lastUpdated.hour}:${center.lastUpdated.minute}',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const Spacer(),
        Chip(
          label: Text(center.status.name.toUpperCase()),
          backgroundColor: Colors.blueAccent.withOpacity(0.1),
          side: BorderSide.none,
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _infoTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
