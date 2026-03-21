import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/index.dart';
import '../providers/index.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centerAsync = ref.watch(currentCenterProvider);
    final evacueeCountAsync = ref.watch(evacueeCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.indigo,
      ),
      body: centerAsync.when(
        data: (center) {
          if (center == null) {
            return const Center(child: Text('No evacuation center assigned'));
          }
          return evacueeCountAsync.when(
            data: (count) => _buildDashboard(context, ref, center, count),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text('Error loading evacuee count: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading center: $err')),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    EvacuationCenter center,
    int evacueeCount,
  ) {
    final safeCapacity = center.totalCapacity;
    final availableSpaces = (safeCapacity - evacueeCount).clamp(
      0,
      safeCapacity,
    );
    final occupancyRate = safeCapacity == 0
        ? 0.0
        : (evacueeCount / safeCapacity * 100);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Center Name
          Text(
            center.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Status Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(center.status),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getStatusText(center.status),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Capacity Info
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Total Capacity',
                  value: center.totalCapacity.toString(),
                  icon: Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  title: 'Current Occupancy',
                  value: evacueeCount.toString(),
                  icon: Icons.group,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Available Spaces
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Available Spaces',
                  value: availableSpaces.toString(),
                  icon: Icons.chair,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  title: 'Occupancy Rate',
                  value: '${occupancyRate.toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Quick Action Buttons
          Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildActionButton(
                icon: Icons.add_circle_outline,
                label: 'Add Evacuee',
                onPressed: () async {
                  final result = await context.push('/register');
                  if (result == true && context.mounted) {
                    ref.invalidate(currentCenterProvider);
                    ref.invalidate(evacueeCountProvider);
                  }
                },
                color: Colors.green,
              ),
              _buildActionButton(
                icon: Icons.remove_circle_outline,
                label: 'Remove Evacuee',
                onPressed: () => _removeEvacuee(context, ref),
                color: Colors.red,
              ),
              _buildActionButton(
                icon: Icons.medical_services,
                label: 'Supplies',
                onPressed: () {
                  context.push('/supplies');
                },
                color: Colors.blue,
              ),
              _buildActionButton(
                icon: Icons.meeting_room,
                label: 'Stations',
                onPressed: () {
                  context.push('/stations');
                },
                color: Colors.orange,
              ),
              _buildActionButton(
                icon: Icons.people,
                label: 'Evacuees',
                onPressed: () async {
                  await context.push('/evacuees');
                  ref.invalidate(currentCenterProvider);
                  ref.invalidate(evacueeCountProvider);
                },
                color: Colors.purple,
              ),
              _buildActionButton(
                icon: Icons.sync,
                label: 'Sync',
                onPressed: () {
                  context.push('/sync');
                },
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Medical Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Row(
              children: [
                Icon(Icons.local_hospital, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Medical Services: ${center.medicalAvailable ? 'Available' : 'Not Available'}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeEvacuee(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseServiceProvider);
    final evacuees = await db.getAllEvacuees();

    if (evacuees.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No evacuees to remove')));
      return;
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        children: evacuees.map((evacuee) {
          return ListTile(
            title: Text(evacuee.name ?? 'ID: ${evacuee.id}'),
            subtitle: Text('Age: ${evacuee.ageGroup.name}'),
            trailing: const Icon(Icons.delete, color: Colors.red),
            onTap: () async {
              await db.removeEvacuee(evacuee.id);
              if (!context.mounted) return;
              Navigator.pop(context);
              ref.invalidate(currentCenterProvider);
              ref.invalidate(evacueeCountProvider);
            },
          );
        }).toList(),
      ),
    );
  }

  Color _getStatusColor(CenterStatus status) {
    switch (status) {
      case CenterStatus.operational:
        return Colors.green;
      case CenterStatus.nearCapacity:
        return Colors.orange;
      case CenterStatus.atCapacity:
        return Colors.red;
      case CenterStatus.closed:
        return Colors.grey;
    }
  }

  String _getStatusText(CenterStatus status) {
    switch (status) {
      case CenterStatus.operational:
        return 'OPERATIONAL';
      case CenterStatus.nearCapacity:
        return 'NEAR CAPACITY';
      case CenterStatus.atCapacity:
        return 'AT CAPACITY';
      case CenterStatus.closed:
        return 'CLOSED';
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    Color color = Colors.blue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
