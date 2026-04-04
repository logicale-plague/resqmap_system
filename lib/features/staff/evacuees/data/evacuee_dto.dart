import 'package:kalig_onan_evac_system/features/staff/evacuees/domain/evacuee.dart';

Map<String, dynamic> evacueeToRow(Evacuee evacuee) {
  return {
    'id': evacuee.id,
    'name': evacuee.name,
    'stationId': evacuee.stationId,
    'ageGroup': evacuee.ageGroup.index,
    'medicalCondition': evacuee.medicalCondition.index,
    'registeredAt': evacuee.registeredAt.toIso8601String(),
    'synced': evacuee.synced ? 1 : 0,
    'active': evacuee.active ? 1 : 0,
  };
}

Map<String, Object?> evacueeToPartialRow(Evacuee evacuee) {
  return {
    'name': evacuee.name,
    'stationId': evacuee.stationId,
    'ageGroup': evacuee.ageGroup.index,
    'medicalCondition': evacuee.medicalCondition.index,
    'synced': evacuee.synced ? 1 : 0,
    'active': evacuee.active ? 1 : 0,
  };
}

Evacuee evacueeFromRow(Map<String, dynamic> row) {
  return Evacuee(
    id: row['id'] as String,
    name: row['name'] as String?,
    stationId: row['stationId'] as String?,
    ageGroup: AgeGroup.values[row['ageGroup'] as int],
    medicalCondition: MedicalCondition.values[row['medicalCondition'] as int],
    registeredAt: DateTime.parse(row['registeredAt'] as String),
    synced: (row['synced'] as int) == 1,
    active: ((row['active'] as int?) ?? 1) == 1,
  );
}
