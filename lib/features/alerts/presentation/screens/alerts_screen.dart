import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/indices/models_index.dart';
import 'package:kalig_onan_evac_system/core/indices/provider_index.dart';
import 'package:kalig_onan_evac_system/core/utils/id_service.dart';
import 'package:kalig_onan_evac_system/core/widgets/index.dart';
import 'package:kalig_onan_evac_system/features/alerts/application/create_alert.dart';
import 'package:kalig_onan_evac_system/features/alerts/application/mark_alert_read.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(allAlertsProvider);

    return Scaffold(
      appBar: buildScreenAppBar(
        title: 'Alerts',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(allAlertsProvider),
          ),
        ],
      ),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return const AppEmptyState(
              icon: Icons.check_circle,
              message: 'No alerts',
              iconSize: 64,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final color = _getSeverityColor(alert.severity);

              return AppListItemCard(
                leftBorderColor: color,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: _getSeverityIcon(alert.severity)),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getSeverityText(alert.severity),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        alert.message,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  '${alert.createdAt.toLocal().toString().substring(0, 16)}${alert.read ? ' • Read' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: alert.read
                    ? null
                    : Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                onTap: () async {
                  if (!alert.read) {
                    final db = ref.read(databaseServiceProvider);
                    try {
                      await db.markAlertAsRead(alert.id);
                      ref.invalidate(allAlertsProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to mark alert as read: $e'),
                          ),
                        );
                      }
                    } finally {
                      if (context.mounted) {
                        _showAlertDetails(context, alert);
                      }
                    }
                    return;
                  }
                  if (context.mounted) {
                    _showAlertDetails(context, alert);
                  }
                },
              );
            },
          );
        },
        loading: () => const AppLoadingState(),
        error: (err, stack) => AppErrorState(error: err, stackTrace: stack),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSendAlertDialog(context, ref),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Colors.blue;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.urgent:
        return Colors.red;
    }
  }

  String _getSeverityText(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return 'INFO';
      case AlertSeverity.warning:
        return 'WARNING';
      case AlertSeverity.urgent:
        return 'URGENT';
    }
  }

  Icon _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return const Icon(Icons.info);
      case AlertSeverity.warning:
        return const Icon(Icons.warning);
      case AlertSeverity.urgent:
        return const Icon(Icons.error);
    }
  }

  void _showAlertDetails(BuildContext context, Alert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getSeverityText(alert.severity)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text(
              'Time: ${alert.createdAt.toLocal()}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSendAlertDialog(BuildContext context, WidgetRef ref) {
    final messageController = TextEditingController();
    AlertSeverity selectedSeverity = AlertSeverity.warning;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Send Alert to Nearby Users'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Message'),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter alert message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Severity'),
                const SizedBox(height: 8),
                SegmentedButton<AlertSeverity>(
                  segments: AlertSeverity.values
                      .map(
                        (severity) => ButtonSegment(
                          value: severity,
                          label: Text(severity.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  selected: {selectedSeverity},
                  onSelectionChanged: (newSelection) {
                    setState(() => selectedSeverity = newSelection.first);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (messageController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a message')),
                  );
                  return;
                }

                final db = ref.read(databaseServiceProvider);
                final center = await ref.read(currentCenterProvider.future);
                if (center == null) {
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
                final alert = Alert(
                  id: IdService.newId(),
                  evacuationCenterId: center.id,
                  message: messageController.text,
                  severity: selectedSeverity,
                  createdAt: DateTime.now(),
                );

                await db.insertAlert(alert);
                if (!context.mounted) return;
                Navigator.pop(context);
                ref.invalidate(allAlertsProvider);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alert sent to nearby users')),
                );
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
