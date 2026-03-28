import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';

Map<String, dynamic> userToMap(User user) {
  return {
    "id": user.id,
    "latitude": user.latitude,
    "longitude": user.longitude,
    "postalCode": user.postalCode,
    "fullAddress": user.fullAddress,
    "username": user.username,
    "email": user.email,
    "dateOfBirth": user.dateOfBirth.toIso8601String(),
    "role": user.role.index,
    "createdAt": user.createdAt.toIso8601String(),
  };
}

User userFromMap(Map<String, dynamic> map) {
  return User(
    id: map["id"] as String,
    latitude: (map["latitude"] as num?)?.toDouble(),
    longitude: (map["longitude"] as num?)?.toDouble(),
    postalCode: map["postalCode"] as String?,
    fullAddress: map["fullAddress"] as String?,
    username: map["username"] as String,
    email: map["email"] as String,
    dateOfBirth: DateTime.parse(map["dateOfBirth"] as String),
    role: UserPermission.values[map["role"] as int],
    createdAt: DateTime.parse(map["createdAt"] as String),
  );
}
