import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/index.dart';
import '../providers/index.dart';

class CentersScreen extends ConsumerWidget {
  const CentersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centersAsync = ref.watch(allCentersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Evacuation Centers',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
      ),
      body: centersAsync.when(
        data: (centers) {
          if (centers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_work_outlined,
                    size: 54,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No evacuation centers yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/map'),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View Map'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: centers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final center = centers[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(center.status),
                    child: const Icon(Icons.apartment, color: Colors.white),
                  ),
                  title: Text(
                    center.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          text:
                              '${center.currentOccupancy} / ${center.totalCapacity} occupied',
                          color: Colors.blue[100]!,
                        ),
                        _InfoChip(
                          text: _statusText(center.status),
                          color: _statusColor(center.status).withAlpha(55),
                        ),
                        _InfoChip(
                          text: center.medicalAvailable
                              ? 'Medical available'
                              : 'No medical services',
                          color: center.medicalAvailable
                              ? Colors.green[100]!
                              : Colors.red[100]!,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading centers: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/map'),
        icon: const Icon(Icons.map),
        label: const Text('View Map'),
      ),
    );
  }

  String _statusText(CenterStatus status) {
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

  Color _statusColor(CenterStatus status) {
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
}

class _InfoChip extends StatelessWidget {
  final String text;
  final Color color;

  const _InfoChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
