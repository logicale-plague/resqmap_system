enum AgeGroup { child, adult, elderly }

enum MedicalCondition { none, minor, serious }

class Evacuee {
  final String id;
  final String? name;
  final String? stationId;
  final AgeGroup ageGroup;
  final MedicalCondition medicalCondition;
  final DateTime registeredAt;
  final bool synced;
  final bool active;

  const Evacuee({
    required this.id,
    this.name,
    this.stationId,
    required this.ageGroup,
    required this.medicalCondition,
    required this.registeredAt,
    this.synced = false,
    this.active = true,
  });

  Evacuee copyWith({
    String? id,
    String? name,
    String? stationId,
    AgeGroup? ageGroup,
    MedicalCondition? medicalCondition,
    DateTime? registeredAt,
    bool? synced,
    bool? active,
    bool clearStationId = false,
  }) {
    return Evacuee(
      id: id ?? this.id,
      name: name ?? this.name,
      stationId: clearStationId ? null : (stationId ?? this.stationId),
      ageGroup: ageGroup ?? this.ageGroup,
      medicalCondition: medicalCondition ?? this.medicalCondition,
      registeredAt: registeredAt ?? this.registeredAt,
      synced: synced ?? this.synced,
      active: active ?? this.active,
    );
  }

  @override
  String toString() =>
      'Evacuee(id: $id, name: $name, stationId: $stationId, ageGroup: $ageGroup, medicalCondition: $medicalCondition)';
}
