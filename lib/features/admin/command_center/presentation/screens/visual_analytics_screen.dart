import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/connectivity_provider.dart';

class VisualAnalyticsScreen extends ConsumerWidget {
  const VisualAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(connectivityProvider);

    // Use streaming connectivity status with fallback to offline
    bool isOnline = isOnlineAsync.when(
      data: (online) => online,
      loading: () => true, // Assume online while checking
      error: (err, stack) => false, // Assume offline on error
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Visual Analytics'), elevation: 0),
      body: isOnline
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Visual Analytics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI-powered data visualization and insights',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Evacuation Centers Distribution Chart
                  _AnalyticsCard(
                    title: 'Evacuation Centers Distribution',
                    child: _buildPlaceholderChart(),
                  ),
                  const SizedBox(height: 16),

                  // Capacity Utilization Chart
                  _AnalyticsCard(
                    title: 'Capacity Utilization',
                    child: _buildPlaceholderChart(),
                  ),
                  const SizedBox(height: 16),

                  // Supply Status Heatmap
                  _AnalyticsCard(
                    title: 'Supply Status Heatmap',
                    child: _buildPlaceholderHeatmap(),
                  ),
                  const SizedBox(height: 16),

                  // AI Insights
                  _AnalyticsCard(
                    title: 'AI Insights & Predictions',
                    child: _buildAIInsights(),
                  ),
                ],
              ),
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

  Widget _buildPlaceholderChart() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Chart Placeholder',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderHeatmap() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.heat_pump, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Heatmap Placeholder',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsights() {
    return Column(
      children: [
        _InsightItem(
          title: 'Supply Prediction',
          description: 'Medicine shortage expected in Center 3 within 2 days',
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _InsightItem(
          title: 'Overcrowding Alert',
          description: 'Center 7 approaching capacity limit (85%)',
          color: Colors.red,
        ),
        const SizedBox(height: 12),
        _InsightItem(
          title: 'Recommendation',
          description: 'Transfer 20 evacuees from Center 5 to Center 2',
          color: Colors.green,
        ),
      ],
    );
  }
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
