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
