import 'package:kalig_onan_evac_system/features/alerts/domain/alert.dart';

Map<String, dynamic> alertToRow(Alert alert) {
  return {
    'id': alert.id,
    'evacuationCenterId': alert.evacuationCenterId,
    'message': alert.message,
    'severity': alert.severity.index,
    'createdAt': alert.createdAt.toIso8601String(),
    'read': alert.read ? 1 : 0,
    'synced': alert.synced ? 1 : 0,
  };
}

Alert alertFromRow(Map<String, dynamic> row) {
  final rawSeverity = row['severity'];
  final severityIndex = rawSeverity is int
      ? rawSeverity
      : rawSeverity is num
      ? rawSeverity.toInt()
      : -1;
  final severity =
      severityIndex >= 0 && severityIndex < AlertSeverity.values.length
      ? AlertSeverity.values[severityIndex]
      : AlertSeverity.values.first;

  return Alert(
    id: row['id'] as String,
    evacuationCenterId: row['evacuationCenterId'] as String,
    message: row['message'] as String,
    severity: severity,
    createdAt: DateTime.parse(row['createdAt'] as String),
    read: (row['read'] as int) == 1,
    synced: row.containsKey('synced') ? (row['synced'] as int) == 1 : false,
  );
}
