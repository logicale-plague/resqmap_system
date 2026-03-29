import 'package:kalig_onan_evac_system/features/staff/supplies/domain/supply.dart';

Map<String, dynamic> supplyToRow(Supply supply) {
  return {
    'id': supply.id,
    'evacuationCenterId': supply.evacuationCenterId,
    'name': supply.name,
    'currentStock': supply.currentStock,
    'usageRatePerDay': supply.usageRatePerDay,
    'lastRestocked': supply.lastRestocked.toIso8601String(),
    'synced': supply.synced ? 1 : 0,
  };
}

Supply supplyFromRow(Map<String, dynamic> row) {
  return Supply(
    id: row['id'] as String,
    evacuationCenterId: row['evacuationCenterId'] as String,
    name: row['name'] as String,
    currentStock: row['currentStock'] as int,
    usageRatePerDay: row['usageRatePerDay'] as int,
    lastRestocked: DateTime.parse(row['lastRestocked'] as String),
    synced: (row['synced'] as int) == 1,
  );
}
