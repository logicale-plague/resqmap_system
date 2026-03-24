import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommandCenterDashboardScreen extends ConsumerWidget {
  const CommandCenterDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Center Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Overview Dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Statistics Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StatisticCard(
                  title: 'Total Evacuation Centers',
                  count: '12',
                  color: Colors.blue,
                  icon: Icons.location_city,
                ),
                _StatisticCard(
                  title: 'Overcrowded Centers',
                  count: '3',
                  color: Colors.orange,
                  icon: Icons.warning,
                ),
                _StatisticCard(
                  title: 'Supply Shortages',
                  count: '5',
                  color: Colors.red,
                  icon: Icons.error,
                ),
                _StatisticCard(
                  title: 'Normal Status',
                  count: '4',
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Supply Shortages Details
            Text(
              'Supply Shortage Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _SupplyShortagesList(),
            const SizedBox(height: 32),

            // Overcrowded Centers Details
            Text(
              'Overcrowded Centers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _OvercrowdedCentersList(),
          ],
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final IconData icon;

  const _StatisticCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.7), color.withOpacity(0.3)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                count,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplyShortagesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text('Evacuation Center ${index + 1}'),
            subtitle: Text('Missing: Medicine, Water'),
            trailing: const Icon(Icons.error, color: Colors.red),
          ),
        );
      },
    );
  }
}

class _OvercrowdedCentersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text('Evacuation Center ${index + 4}'),
            subtitle: Text('Capacity: ${80 + (index * 5)}%'),
            trailing: const Icon(Icons.warning, color: Colors.orange),
          ),
        );
      },
    );
  }
}
