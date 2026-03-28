import 'package:kalig_onan_evac_system/core/indices/models_index.dart';

Map<String, dynamic> stationToMap(Station station) {
  return {
    'id': station.id,
    'name': station.name,
    'evacuationCenterId': station.evacuationCenterId,
    'capacity': station.capacity,
    'allowedAgeGroup': station.allowedAgeGroup?.name,
    'allowedMedicalCondition': station.allowedMedicalCondition?.name,
    'synced': station.synced ? 1 : 0,
    'active': station.active ? 1 : 0,
  };
}

Station stationFromMap(Map<String, dynamic> map) {
  final rawAge = map['allowedAgeGroup'];
  final rawMedical = map['allowedMedicalCondition'];

  return Station(
    id: map['id'] as String,
    name: map['name'] as String,
    evacuationCenterId: map['evacuationCenterId'] as String,
    capacity: (map['capacity'] as num?)?.toInt() ?? 0,
    allowedAgeGroup: _parseAgeGroup(rawAge),
    allowedMedicalCondition: _parseMedicalCondition(rawMedical),
    synced: (map['synced'] as int? ?? 0) == 1,
    active: (map['active'] as int? ?? 1) == 1,
  );
}

AgeGroup? _parseAgeGroup(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    for (final ageGroup in AgeGroup.values) {
      if (ageGroup.name == value) return ageGroup;
    }
    return null;
  }
  if (value is num) {
    final index = value.toInt();
    if (index < 0 || index >= AgeGroup.values.length) return null;
    return AgeGroup.values[index];
  }
  return null;
}

MedicalCondition? _parseMedicalCondition(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    for (final medicalCondition in MedicalCondition.values) {
      if (medicalCondition.name == value) return medicalCondition;
    }
    return null;
  }
  if (value is num) {
    final index = value.toInt();
    if (index < 0 || index >= MedicalCondition.values.length) return null;
    return MedicalCondition.values[index];
  }
  return null;
}
