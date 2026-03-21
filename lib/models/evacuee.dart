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

  const Evacuee({
    required this.id,
    this.name,
    this.stationId,
    required this.ageGroup,
    required this.medicalCondition,
    required this.registeredAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stationId': stationId,
      'ageGroup': ageGroup.index,
      'medicalCondition': medicalCondition.index,
      'registeredAt': registeredAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory Evacuee.fromMap(Map<String, dynamic> map) {
    return Evacuee(
      id: map['id'] as String,
      name: map['name'] as String?,
      stationId: map['stationId'] as String?,
      ageGroup: AgeGroup.values[map['ageGroup'] as int],
      medicalCondition: MedicalCondition.values[map['medicalCondition'] as int],
      registeredAt: DateTime.parse(map['registeredAt'] as String),
      synced: (map['synced'] as int) == 1,
    );
  }

  Evacuee copyWith({
    String? id,
    String? name,
    String? stationId,
    AgeGroup? ageGroup,
    MedicalCondition? medicalCondition,
    DateTime? registeredAt,
    bool? synced,
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
    );
  }

  @override
  String toString() =>
      'Evacuee(id: $id, name: $name, stationId: $stationId, ageGroup: $ageGroup, medicalCondition: $medicalCondition)';
}
