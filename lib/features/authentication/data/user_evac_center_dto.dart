import 'package:kalig_onan_evac_system/features/authentication/domain/user_to_evac_center.dart';

Map<String, dynamic> userEvacCenterToMap(UserToEvacCenter mapping) {
  return {
    'id': mapping.id,
    'user_id': mapping.userId,
    'evac_center_id': mapping.centerId,
    'active': mapping.active ? 1 : 0,
  };
}

Map<String, dynamic> userEvacCenterToLocalMap(UserToEvacCenter mapping) {
  return {
    'id': mapping.id,
    'userId': mapping.userId,
    'evacuationCenterId': mapping.centerId,
    'active': mapping.active ? 1 : 0,
  };
}

UserToEvacCenter userEvacCenterFromMap(Map<String, dynamic> map) {
  return UserToEvacCenter(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    centerId: map['evac_center_id'] as String,
    active: _readActiveFlag(map),
  );
}

UserToEvacCenter userEvacCenterFromLocalMap(Map<String, dynamic> map) {
  return UserToEvacCenter(
    id: map['id'] as String,
    userId: map['userId'] as String,
    centerId: map['evacuationCenterId'] as String,
    active: _readActiveFlag(map),
  );
}

bool _readActiveFlag(Map<String, dynamic> map) {
  final rawActive = map['active'] ?? map['is_active'] ?? 1;
  if (rawActive is bool) {
    return rawActive;
  }
  if (rawActive is num) {
    return rawActive.toInt() == 1;
  }
  if (rawActive is String) {
    return rawActive == '1' || rawActive.toLowerCase() == 'true';
  }
  return true;
}
