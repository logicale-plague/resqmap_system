import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kalig_onan_evac_system/core/indices/models_index.dart';
import 'package:kalig_onan_evac_system/core/indices/provider_index.dart';

class CommandCenterDashboardScreen extends StatelessWidget {
  const CommandCenterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            const _OverviewStatisticsGrid(),
            const SizedBox(height: 32),

            // Supply Shortages Details
            Text(
              'Supply Shortage Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const _SupplyShortagesList(),
            const SizedBox(height: 32),

            // Overcrowded Centers Details
            Text(
              'Overcrowded Centers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const _OvercrowdedCentersSection(),
          ],
        ),
      ),
    );
  }
}

class _OverviewStatisticsGrid extends ConsumerWidget {
  const _OverviewStatisticsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centersAsync = ref.watch(allCentersProvider);
    final shortagesAsync = ref.watch(lowStockSuppliesByCenterProvider);

    return centersAsync.when(
      data: (centers) {
        final overcrowdedCenters = centers.where(_isOvercrowdedCenter).length;
        final normalCenters = (centers.length - overcrowdedCenters).clamp(
          0,
          centers.length,
        );

        return shortagesAsync.when(
          data: (shortagesByCenter) {
            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StatisticCard(
                  title: 'Total Evacuation Centers',
                  count: centers.length.toString(),
                  color: Colors.blue,
                  icon: Icons.location_city,
                ),
                _StatisticCard(
                  title: 'Overcrowded Centers',
                  count: overcrowdedCenters.toString(),
                  color: Colors.orange,
                  icon: Icons.warning,
                ),
                _StatisticCard(
                  title: 'Supply Shortages',
                  count: shortagesByCenter.length.toString(),
                  color: Colors.red,
                  icon: Icons.error,
                ),
                _StatisticCard(
                  title: 'Normal Status',
                  count: normalCenters.toString(),
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Failed to load statistics: $error'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Failed to load centers: $error'),
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
            colors: [color.withAlpha(180), color.withAlpha(75)],
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

class _SupplyShortagesList extends ConsumerWidget {
  const _SupplyShortagesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centersAsync = ref.watch(allCentersProvider);
    final shortagesAsync = ref.watch(lowStockSuppliesByCenterProvider);

    return centersAsync.when(
      data: (centers) {
        final centersById = <String, EvacuationCenter>{
          for (final center in centers) center.id: center,
        };

        return shortagesAsync.when(
          data: (shortagesByCenter) {
            final entries = shortagesByCenter.entries.toList();
            if (entries.isEmpty) {
              return const SizedBox.shrink();
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final center = centersById[entry.key];
                final missingSupplies = entry.value
                    .map((supply) => supply.name)
                    .toSet()
                    .join(', ');

                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    title: Text(center?.name ?? 'Unknown Center'),
                    subtitle: Text('Missing: $missingSupplies'),
                    trailing: const Icon(Icons.error, color: Colors.red),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Failed to load shortages: $error'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Failed to load centers: $error'),
    );
  }
}

class _OvercrowdedCentersSection extends ConsumerWidget {
  const _OvercrowdedCentersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centersAsync = ref.watch(allCentersProvider);

    return centersAsync.when(
      data: (centers) {
        final overcrowdedCenters = centers
            .where(_isOvercrowdedCenter)
            .toList(growable: false);
        return _OvercrowdedCentersList(overcrowdedCenters: overcrowdedCenters);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Failed to load centers: $error'),
    );
  }
}

class _OvercrowdedCentersList extends StatelessWidget {
  final List<EvacuationCenter> overcrowdedCenters;

  const _OvercrowdedCentersList({required this.overcrowdedCenters});

  @override
  Widget build(BuildContext context) {
    if (overcrowdedCenters.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: overcrowdedCenters.length,
      itemBuilder: (context, index) {
        final center = overcrowdedCenters[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text(center.name),
            subtitle: Text(
              'Capacity: ${center.occupancyPercentage.toStringAsFixed(0)}%',
            ),
            trailing: const Icon(Icons.warning, color: Colors.orange),
          ),
        );
      },
    );
  }
}

bool _isOvercrowdedCenter(EvacuationCenter center) {
  return center.totalCapacity > 0 &&
      (center.currentOccupancy / center.totalCapacity) > 0.80;
}
