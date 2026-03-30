import 'package:kalig_onan_evac_system/core/indices/models_index.dart';

/// For local SQLite database (uses camelCase column names)
Map<String, dynamic> stationToMap(Station station) {
  return {
    'id': station.id,
    'name': station.name,
    'evacuationCenterId': station.evacuationCenterId,
    'capacity': station.capacity,
    'allowedAgeGroup': station.allowedAgeGroup?.index,
    'allowedMedicalCondition': station.allowedMedicalCondition?.index,
    'synced': station.synced ? 1 : 0,
    'active': station.active ? 1 : 0,
  };
}

/// For Supabase remote storage (uses snake_case column names)
Map<String, dynamic> stationToRemoteMap(Station station) {
  return {
    'id': station.id,
    'name': station.name,
    'evacuation_center_id': station.evacuationCenterId,
    'capacity': station.capacity,
    'allowed_age_group': station.allowedAgeGroup?.index,
    'allowed_medical_condition': station.allowedMedicalCondition?.index,
    'synced': station.synced ? 1 : 0,
  };
}

Station stationFromMap(Map<String, dynamic> map) {
  // Support both local (camelCase) and remote (snake_case) formats
  final rawAge = map['allowedAgeGroup'] ?? map['allowed_age_group'];
  final rawMedical =
      map['allowedMedicalCondition'] ?? map['allowed_medical_condition'];

  return Station(
    id: map['id'] as String,
    name: map['name'] as String,
    evacuationCenterId:
        map['evacuationCenterId'] ?? map['evacuation_center_id'] as String,
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
