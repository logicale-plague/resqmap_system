import '../../evacuees/domain/evacuee.dart';

class Station {
  final String id;
  final String name;
  final String evacuationCenterId;
  final int capacity;
  final AgeGroup? allowedAgeGroup;
  final MedicalCondition? allowedMedicalCondition;
  final bool synced;

  const Station({
    required this.id,
    required this.name,
    required this.evacuationCenterId,
    required this.capacity,
    this.allowedAgeGroup,
    this.allowedMedicalCondition,
    this.synced = false,
  });

  bool allows({
    required AgeGroup ageGroup,
    required MedicalCondition medicalCondition,
  }) {
    final ageAllowed = allowedAgeGroup == null || allowedAgeGroup == ageGroup;
    final medicalAllowed =
        allowedMedicalCondition == null ||
        allowedMedicalCondition == medicalCondition;
    return ageAllowed && medicalAllowed;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'evacuationCenterId': evacuationCenterId,
      'capacity': capacity,
      'allowedAgeGroup': allowedAgeGroup?.index,
      'allowedMedicalCondition': allowedMedicalCondition?.index,
      'synced': synced ? 1 : 0,
    };
  }

  factory Station.fromMap(Map<String, dynamic> map) {
    final rawAge = map['allowedAgeGroup'];
    final rawMedical = map['allowedMedicalCondition'];

    return Station(
      id: map['id'] as String,
      name: map['name'] as String,
      evacuationCenterId: map['evacuationCenterId'] as String,
      capacity: (map['capacity'] as num?)?.toInt() ?? 0,
      allowedAgeGroup: rawAge == null
          ? null
          : AgeGroup.values[(rawAge as num).toInt()],
      allowedMedicalCondition: rawMedical == null
          ? null
          : MedicalCondition.values[(rawMedical as num).toInt()],
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  Station copyWith({
    String? id,
    String? name,
    String? evacuationCenterId,
    int? capacity,
    AgeGroup? allowedAgeGroup,
    MedicalCondition? allowedMedicalCondition,
    bool? synced,
    bool clearAllowedAgeGroup = false,
    bool clearAllowedMedicalCondition = false,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      evacuationCenterId: evacuationCenterId ?? this.evacuationCenterId,
      capacity: capacity ?? this.capacity,
      allowedAgeGroup: clearAllowedAgeGroup
          ? null
          : (allowedAgeGroup ?? this.allowedAgeGroup),
      allowedMedicalCondition: clearAllowedMedicalCondition
          ? null
          : (allowedMedicalCondition ?? this.allowedMedicalCondition),
      synced: synced ?? this.synced,
    );
  }
}
