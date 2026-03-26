import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/stations/data/station_repository_impl.dart';

import 'package:kalig_onan_evac_system/core/indices/models_index.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';

final stationsByCenterProvider = FutureProvider.family<List<Station>, String>((
  ref,
  centerId,
) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getStationsForCenter(centerId);
});

final eligibleStationsProvider =
    FutureProvider.family<
      List<Station>,
      ({String centerId, AgeGroup ageGroup, MedicalCondition medicalCondition})
    >((ref, params) async {
      final db = ref.watch(databaseServiceProvider);
      return db.getEligibleStations(
        centerId: params.centerId,
        ageGroup: params.ageGroup,
        medicalCondition: params.medicalCondition,
      );
    });

final stationByIdProvider = FutureProvider.family<Station?, String>((
  ref,
  stationId,
) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getStationById(stationId);
});
