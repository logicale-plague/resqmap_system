import 'package:flutter/material.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/domain/evacuee.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/domain/station.dart';

String getAgeGroupDisplay(AgeGroup ageGroup) {
  switch (ageGroup) {
    case AgeGroup.child:
      return 'Child';
    case AgeGroup.adult:
      return 'Adult';
    case AgeGroup.elderly:
      return 'Elderly';
  }
}

String getMedicalConditionDisplay(MedicalCondition condition) {
  switch (condition) {
    case MedicalCondition.none:
      return 'None';
    case MedicalCondition.minor:
      return 'Minor';
    case MedicalCondition.serious:
      return 'Serious';
  }
}

Color getMedicalConditionColor(MedicalCondition condition) {
  switch (condition) {
    case MedicalCondition.none:
      return Colors.green;
    case MedicalCondition.minor:
      return Colors.orange;
    case MedicalCondition.serious:
      return Colors.red;
  }
}

String getStationLabel(Station station) {
  final ageLabel = station.allowedAgeGroup != null
      ? getAgeGroupDisplay(station.allowedAgeGroup!)
      : 'Any age group';
  final medicalLabel = station.allowedMedicalCondition != null
      ? getMedicalConditionDisplay(station.allowedMedicalCondition!)
      : 'Any condition';
  return '${station.name} ($ageLabel / $medicalLabel)';
}

Widget getAgeGroupIcon(AgeGroup ageGroup) {
  switch (ageGroup) {
    case AgeGroup.child:
      return const Icon(Icons.child_care, size: 36, color: Colors.blue);
    case AgeGroup.adult:
      return const Icon(Icons.person, size: 36, color: Colors.blue);
    case AgeGroup.elderly:
      return const Icon(Icons.elderly, size: 36, color: Colors.blue);
  }
}
