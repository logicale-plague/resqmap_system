import 'package:kalig_onan_evac_system/features/centers/shared/index.dart';

Map<String, dynamic> centerToMap(EvacuationCenter center) {
  return {
    'id': center.id,
    'name': center.name,
    'commandCenterId': center.commandCenterId,
    'latitude': center.latitude,
    'longitude': center.longitude,
    'totalCapacity': center.totalCapacity,
    'currentOccupancy': center.currentOccupancy,
    'status': center.status.index,
    'medicalAvailable': center.medicalAvailable ? 1 : 0,
    'lastUpdated': center.lastUpdated.toIso8601String(),
    'synced': center.synced ? 1 : 0,
  };
}

Map<String, dynamic> centerToRemoteMap(EvacuationCenter center) {
  return {
    'id': center.id,
    'name': center.name,
    'command_center_id': center.commandCenterId,
    'latitude': center.latitude,
    'longitude': center.longitude,
    'total_capacity': center.totalCapacity,
    'current_occupancy': center.currentOccupancy,
    'status': center.status.index,
    'medical_available': center.medicalAvailable ? 1 : 0,
    'last_updated': center.lastUpdated.toIso8601String(),
    'synced': center.synced ? 1 : 0,
  };
}

EvacuationCenter centerFromMap(Map<String, dynamic> map) {
  final rawStatus = map['status'];
  final parsedStatus = _parseCenterStatus(rawStatus);

  return EvacuationCenter(
    id: map['id'] as String,
    name: map['name'] as String,
    commandCenterId:
        map['commandCenterId'] as String? ??
        // map['commandcenterid'] as String? ??
        // map['command_center_id'] as String? ??
        'default-command-center',
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    totalCapacity: map['totalCapacity'] as int,
    currentOccupancy: map['currentOccupancy'] as int,
    status: parsedStatus,
    medicalAvailable: (map['medicalAvailable'] as int?) == 1,
    lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    synced: (map['synced'] as int?) == 1,
  );
}

CenterStatus _parseCenterStatus(dynamic rawStatus) {
  if (rawStatus is String) {
    for (final status in CenterStatus.values) {
      if (status.name == rawStatus) return status;
    }
  }

  if (rawStatus is num) {
    final index = rawStatus.toInt();
    if (index >= 0 && index < CenterStatus.values.length) {
      return CenterStatus.values[index];
    }
  }

  return CenterStatus.operational;
}
