import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/connectivity_provider.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/providers/command_center_providers.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';
import 'package:kalig_onan_evac_system/features/staff/supplies/domain/supply.dart';
import 'package:kalig_onan_evac_system/features/staff/supplies/presentation/providers/supply_providers.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class VisualAnalyticsScreen extends ConsumerWidget {
  const VisualAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(connectivityProvider);
    final selectedCommandCenterAsync = ref.watch(currentCommandCenterProvider);
    final selectedCentersAsync = ref.watch(
      selectedCommandCenterCentersProvider,
    );
    final suppliesAsync = ref.watch(allCenterSuppliesProvider);

    // Use streaming connectivity status with fallback to offline
    bool isOnline = isOnlineAsync.when(
      data: (online) => online,
      loading: () => true, // Assume online while checking
      error: (err, stack) => false, // Assume offline on error
    );

    return Scaffold(
      body: isOnline
          ? selectedCommandCenterAsync.when(
              data: (commandCenter) {
                if (commandCenter == null) {
                  return _buildSelectionPrompt(context);
                }

                return selectedCentersAsync.when(
                  data: (centers) {
                    return suppliesAsync.when(
                      data: (supplies) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Visual Analytics',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Command Center: ${commandCenter.name}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 24),
                              _AnalyticsCard(
                                title: 'Evacuation Centers Distribution',
                                child: _buildCenterStatusChart(centers),
                              ),
                              const SizedBox(height: 16),
                              _AnalyticsCard(
                                title: 'Capacity Utilization',
                                child: _buildCapacityChart(centers),
                              ),
                              const SizedBox(height: 16),
                              _AnalyticsCard(
                                title: 'Supply Status by Center',
                                child: _buildSupplyStatusChart(
                                  centers: centers,
                                  supplies: supplies,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _AnalyticsCard(
                                title: 'Medical Support Coverage',
                                child: _buildMedicalCoverageChart(centers),
                              ),
                              const SizedBox(height: 16),
                              _AnalyticsCard(
                                title: 'AI Insights & Predictions',
                                child: _buildAIInsights(
                                  centers: centers,
                                  supplies: supplies,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Text('Failed to load supplies: $error'),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text('Failed to load evacuation centers: $error'),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Failed to load command center: $error')),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Offline Mode',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Visual analytics requires an internet connection',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(connectivityProvider);
                    },
                    child: const Text('Retry Connection'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectionPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Select a command center',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a command center to populate the analytics charts.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterStatusChart(List<EvacuationCenter> centers) {
    final centerCounts = <CenterStatus, int>{
      for (final status in CenterStatus.values) status: 0,
    };
    for (final center in centers) {
      centerCounts[center.status] = (centerCounts[center.status] ?? 0) + 1;
    }

    final chartData = [
      _ChartSegment(
        'Operational',
        centerCounts[CenterStatus.operational]!,
        Colors.green,
      ),
      _ChartSegment(
        'Near Capacity',
        centerCounts[CenterStatus.nearCapacity]!,
        Colors.orange,
      ),
      _ChartSegment(
        'At Capacity',
        centerCounts[CenterStatus.atCapacity]!,
        Colors.red,
      ),
      _ChartSegment('Closed', centerCounts[CenterStatus.closed]!, Colors.grey),
    ].where((segment) => segment.value > 0).toList(growable: false);

    if (chartData.isEmpty) {
      return _buildEmptyChartState('No evacuation centers are available yet.');
    }

    return SizedBox(
      height: 280,
      child: SfCircularChart(
        legend: const Legend(
          isVisible: true,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CircularSeries<_ChartSegment, String>>[
          DoughnutSeries<_ChartSegment, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data.label,
            yValueMapper: (data, _) => data.value,
            pointColorMapper: (data, _) => data.color,
            dataLabelMapper: (data, _) => '${data.value}',
            dataLabelSettings: const DataLabelSettings(isVisible: true),
            innerRadius: '62%',
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityChart(List<EvacuationCenter> centers) {
    if (centers.isEmpty) {
      return _buildEmptyChartState(
        'No centers are assigned to this command center.',
      );
    }

    final chartData =
        centers
            .map(
              (center) => _CapacityData(
                _abbreviatedCenterName(center.name),
                center.currentOccupancy,
                center.availableSpaces,
                center.totalCapacity,
                center.occupancyPercentage,
                center.occupancyPercentage >= 80
                    ? Colors.red
                    : center.occupancyPercentage >= 60
                    ? Colors.orange
                    : Colors.green,
              ),
            )
            .toList(growable: false)
          ..sort((left, right) => right.percentage.compareTo(left.percentage));

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        legend: const Legend(isVisible: true),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: CategoryAxis(
          labelRotation: 30,
          majorGridLines: const MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          minimum: 0,
          maximum: _maxCapacityTotal(chartData),
          interval: _axisIntervalForCapacity(chartData),
          labelFormat: '{value}',
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
        ),
        series: <CartesianSeries<_CapacityData, String>>[
          StackedColumnSeries<_CapacityData, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data.label,
            yValueMapper: (data, _) => data.occupied,
            pointColorMapper: (data, _) => data.color,
            name: 'Occupied',
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            width: 0.7,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
          StackedColumnSeries<_CapacityData, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data.label,
            yValueMapper: (data, _) => data.available,
            pointColorMapper: (data, _) => Colors.blueGrey.shade200,
            name: 'Available',
          ),
        ],
      ),
    );
  }

  Widget _buildSupplyStatusChart({
    required List<EvacuationCenter> centers,
    required List<Supply> supplies,
  }) {
    if (centers.isEmpty) {
      return _buildEmptyChartState(
        'No centers are assigned to this command center.',
      );
    }

    final centerIds = centers.map((center) => center.id).toSet();
    final relatedSupplies = supplies
        .where((supply) => centerIds.contains(supply.evacuationCenterId))
        .toList(growable: false);

    if (relatedSupplies.isEmpty) {
      return _buildEmptyChartState(
        'No supply records found for the selected centers.',
      );
    }

    final chartData = centers
        .map(
          (center) => _SupplyBreakdownData(
            _abbreviatedCenterName(center.name),
            relatedSupplies
                .where((supply) => supply.evacuationCenterId == center.id)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

    return SizedBox(
      height: 320,
      child: SfCartesianChart(
        legend: const Legend(
          isVisible: true,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        primaryXAxis: CategoryAxis(
          labelRotation: 30,
          majorGridLines: const MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          minimum: 0,
          maximum: _maxSupplyCount(chartData),
          interval: _axisIntervalForSupply(chartData),
          labelFormat: '{value}',
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
        ),
        series: <CartesianSeries<_SupplyBreakdownData, String>>[
          StackedColumnSeries<_SupplyBreakdownData, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data.label,
            yValueMapper: (data, _) => data.criticalCount,
            pointColorMapper: (data, _) => Colors.red,
            name: 'Critical',
          ),
          StackedColumnSeries<_SupplyBreakdownData, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data.label,
            yValueMapper: (data, _) => data.lowCount,
            pointColorMapper: (data, _) => Colors.orange,
            name: 'Low',
          ),
          StackedColumnSeries<_SupplyBreakdownData, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data.label,
            yValueMapper: (data, _) => data.watchCount,
            pointColorMapper: (data, _) => Colors.amber,
            name: 'Watch',
          ),
          StackedColumnSeries<_SupplyBreakdownData, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data.label,
            yValueMapper: (data, _) => data.healthyCount,
            pointColorMapper: (data, _) => Colors.green,
            name: 'Healthy',
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalCoverageChart(List<EvacuationCenter> centers) {
    final medicalAvailableCount = centers
        .where((center) => center.medicalAvailable)
        .length;
    final noMedicalCount = centers.length - medicalAvailableCount;

    if (centers.isEmpty) {
      return _buildEmptyChartState(
        'No centers are assigned to this command center.',
      );
    }

    final chartData = <_ChartSegment>[
      _ChartSegment('Medical support', medicalAvailableCount, Colors.teal),
      _ChartSegment('No medical support', noMedicalCount, Colors.blueGrey),
    ].where((segment) => segment.value > 0).toList(growable: false);

    return SizedBox(
      height: 260,
      child: SfCircularChart(
        legend: const Legend(
          isVisible: true,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CircularSeries<_ChartSegment, String>>[
          DoughnutSeries<_ChartSegment, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data.label,
            yValueMapper: (data, _) => data.value,
            pointColorMapper: (data, _) => data.color,
            dataLabelMapper: (data, _) => '${data.value}',
            dataLabelSettings: const DataLabelSettings(isVisible: true),
            innerRadius: '62%',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartState(String message) {
    return SizedBox(
      height: 240,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildAIInsights({
    required List<EvacuationCenter> centers,
    required List<Supply> supplies,
  }) {
    final centerById = {for (final center in centers) center.id: center};
    final trackedSupplies = supplies
        .where((supply) => centerById.containsKey(supply.evacuationCenterId))
        .toList(growable: false);

    final shortageSupply = trackedSupplies
        .where((supply) => supply.daysRemaining != null)
        .reduceOrNull(
          (left, right) =>
              (left.daysRemaining ?? 0) <= (right.daysRemaining ?? 0)
              ? left
              : right,
        );

    final overcrowdedCenter = centers
        .where((center) => center.totalCapacity > 0)
        .reduceOrNull(
          (left, right) => left.occupancyPercentage >= right.occupancyPercentage
              ? left
              : right,
        );

    final leastOccupiedCenter = centers
        .where((center) => center.totalCapacity > 0)
        .reduceOrNull(
          (left, right) => left.occupancyPercentage <= right.occupancyPercentage
              ? left
              : right,
        );

    final criticalSupply =
        shortageSupply != null &&
            shortageSupply.daysRemaining != null &&
            shortageSupply.daysRemaining! <= 7
        ? shortageSupply
        : null;

    final alertOvercrowding =
        overcrowdedCenter != null && overcrowdedCenter.occupancyPercentage >= 80
        ? overcrowdedCenter
        : null;

    return Column(
      children: [
        _InsightItem(
          title: 'Supply Prediction',
          description: criticalSupply == null
              ? 'No supply shortage forecast available for the selected command center.'
              : 'Supply shortage of ${criticalSupply.name} expected in ${centerById[criticalSupply.evacuationCenterId]?.name ?? 'Unknown Center'} within ${criticalSupply.daysRemaining ?? 0} day${(criticalSupply.daysRemaining ?? 0) == 1 ? '' : 's'}',
          color: criticalSupply == null ? Colors.blueGrey : Colors.orange,
        ),
        const SizedBox(height: 12),
        _InsightItem(
          title: 'Overcrowding Alert',
          description: alertOvercrowding == null
              ? 'No overcrowding detected across the selected evacuation centers.'
              : '${alertOvercrowding.name} is the most occupied center at ${alertOvercrowding.occupancyPercentage.toStringAsFixed(0)}% capacity.',
          color: alertOvercrowding == null ? Colors.blueGrey : Colors.red,
        ),
        const SizedBox(height: 12),
        _InsightItem(
          title: 'Recommendation',
          description:
              overcrowdedCenter == null ||
                  leastOccupiedCenter == null ||
                  overcrowdedCenter.id == leastOccupiedCenter.id
              ? 'No transfer recommendation available with the current data.'
              : 'Transfer evacuees from ${overcrowdedCenter.name} to ${leastOccupiedCenter.name} to balance occupancy.',
          color:
              overcrowdedCenter == null ||
                  leastOccupiedCenter == null ||
                  overcrowdedCenter.id == leastOccupiedCenter.id
              ? Colors.blueGrey
              : Colors.green,
        ),
      ],
    );
  }
}

class _ChartSegment {
  final String label;
  final int value;
  final Color color;

  const _ChartSegment(this.label, this.value, this.color);
}

class _CapacityData {
  final String label;
  final int occupied;
  final int available;
  final int totalCapacity;
  final double percentage;
  final Color color;

  const _CapacityData(
    this.label,
    this.occupied,
    this.available,
    this.totalCapacity,
    this.percentage,
    this.color,
  );
}

class _SupplyBreakdownData {
  final String label;
  final List<Supply> supplies;

  const _SupplyBreakdownData(this.label, this.supplies);

  int get criticalCount => supplies.where(_isCriticalSupply).length;

  int get lowCount => supplies.where(_isLowSupply).length;

  int get watchCount => supplies.where(_isWatchSupply).length;

  int get healthyCount => supplies.where(_isHealthySupply).length;

  int get totalSupplyCount => supplies.length;
}

double _maxCapacityTotal(List<_CapacityData> chartData) {
  if (chartData.isEmpty) {
    return 0;
  }

  final maxTotal = chartData
      .map((data) => data.totalCapacity)
      .reduce((left, right) => left > right ? left : right);
  return maxTotal <= 0 ? 1 : maxTotal.toDouble();
}

double _axisIntervalForCapacity(List<_CapacityData> chartData) {
  final maxTotal = _maxCapacityTotal(chartData);
  if (maxTotal <= 10) {
    return 2;
  }
  if (maxTotal <= 50) {
    return 10;
  }
  if (maxTotal <= 100) {
    return 20;
  }
  return 50;
}

double _maxSupplyCount(List<_SupplyBreakdownData> chartData) {
  if (chartData.isEmpty) {
    return 0;
  }

  final maxTotal = chartData
      .map((data) => data.totalSupplyCount)
      .reduce((left, right) => left > right ? left : right);
  return maxTotal <= 0 ? 1 : maxTotal.toDouble();
}

double _axisIntervalForSupply(List<_SupplyBreakdownData> chartData) {
  final maxTotal = _maxSupplyCount(chartData);
  if (maxTotal <= 10) {
    return 2;
  }
  if (maxTotal <= 50) {
    return 10;
  }
  if (maxTotal <= 100) {
    return 20;
  }
  return 50;
}

bool _isCriticalSupply(Supply supply) {
  return supply.daysRemaining != null && supply.daysRemaining! <= 2;
}

bool _isLowSupply(Supply supply) {
  return supply.daysRemaining != null &&
      supply.daysRemaining! > 2 &&
      supply.daysRemaining! <= 7;
}

bool _isWatchSupply(Supply supply) {
  return supply.daysRemaining != null &&
      supply.daysRemaining! > 7 &&
      supply.daysRemaining! <= 14;
}

bool _isHealthySupply(Supply supply) {
  return supply.daysRemaining == null || supply.daysRemaining! > 14;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? reduceOrNull(E Function(E left, E right) combine) {
    final iter = this.iterator;
    if (!iter.moveNext()) {
      return null;
    }

    var value = iter.current;
    while (iter.moveNext()) {
      value = combine(value, iter.current);
    }
    return value;
  }
}

String _abbreviatedCenterName(String name, {int maxChars = 6}) {
  if (name.length <= maxChars) {
    return name;
  }

  return '${name.substring(0, maxChars)}...';
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _AnalyticsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final String title;
  final String description;
  final Color color;

  const _InsightItem({
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
