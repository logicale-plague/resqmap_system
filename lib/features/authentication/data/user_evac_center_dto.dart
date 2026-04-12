import 'package:kalig_onan_evac_system/features/authentication/domain/user_to_evac_center.dart';

Map<String, dynamic> userEvacCenterToMap(UserToEvacCenter mapping) {
  return {
    'id': mapping.id,
    'user_id': mapping.userId,
    'evac_center_id': mapping.centerId,
  };
}

Map<String, dynamic> userEvacCenterToLocalMap(UserToEvacCenter mapping) {
  return {
    'id': mapping.id,
    'userId': mapping.userId,
    'evacuationCenterId': mapping.centerId,
  };
}

UserToEvacCenter userEvacCenterFromMap(Map<String, dynamic> map) {
  return UserToEvacCenter(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    centerId: map['evac_center_id'] as String,
  );
}

UserToEvacCenter userEvacCenterFromLocalMap(Map<String, dynamic> map) {
  return UserToEvacCenter(
    id: map['id'] as String,
    userId: map['userId'] as String,
    centerId: map['evacuationCenterId'] as String,
  );
}
