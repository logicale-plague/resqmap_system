import 'package:kalig_onan_evac_system/features/authentication/domain/user_to_cmd_center.dart';

Map<String, dynamic> userCmdCenterToMap(UserToCmdCenter mapping) {
  return {
    'id': mapping.id,
    'user_id': mapping.userId,
    'cmd_center_id': mapping.cmdCenterId,
  };
}

Map<String, dynamic> userCmdCenterToLocalMap(UserToCmdCenter mapping) {
  return {
    'id': mapping.id,
    'userId': mapping.userId,
    'commandCenterId': mapping.cmdCenterId,
  };
}

UserToCmdCenter userCmdCenterFromMap(Map<String, dynamic> map) {
  return UserToCmdCenter(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    cmdCenterId: map['cmd_center_id'] as String,
  );
}

UserToCmdCenter userCmdCenterFromLocalMap(Map<String, dynamic> map) {
  return UserToCmdCenter(
    id: map['id'] as String,
    userId: map['userId'] as String,
    cmdCenterId: map['commandCenterId'] as String,
  );
}
