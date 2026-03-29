import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/core/services/user_pii_cipher.dart';

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
    "role": user.role.toCode(),
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
    role: UserPermissionSerialization.fromCode(map["role"]),
    createdAt: DateTime.parse(map["createdAt"] as String),
  );
}

Future<Map<String, dynamic>> userToLocalDbMap(
  User user, {
  UserPiiCipher? cipher,
}) async {
  final piiCipher = cipher ?? UserPiiCipher.instance();
  return {
    "id": user.id,
    "latitude": user.latitude,
    "longitude": user.longitude,
    "postalCode": await piiCipher.encryptNullable(user.postalCode),
    "fullAddress": await piiCipher.encryptNullable(user.fullAddress),
    "username": user.username,
    "email": (await piiCipher.encryptNullable(user.email))!,
    "dateOfBirth": (await piiCipher.encryptNullable(
      user.dateOfBirth.toIso8601String(),
    ))!,
    "role": user.role.toCode(),
    "createdAt": user.createdAt.toIso8601String(),
  };
}

Future<User> userFromLocalDbMap(
  Map<String, dynamic> map, {
  UserPiiCipher? cipher,
}) async {
  final piiCipher = cipher ?? UserPiiCipher.instance();
  final decryptedEmail = await piiCipher.decryptNullable(
    map["email"] as String?,
  );
  final decryptedDateOfBirth = await piiCipher.decryptNullable(
    map["dateOfBirth"] as String?,
  );
  if (decryptedEmail == null || decryptedDateOfBirth == null) {
    throw const FormatException('Missing required encrypted user fields.');
  }

  return User(
    id: map["id"] as String,
    latitude: (map["latitude"] as num?)?.toDouble(),
    longitude: (map["longitude"] as num?)?.toDouble(),
    postalCode: await piiCipher.decryptNullable(map["postalCode"] as String?),
    fullAddress: await piiCipher.decryptNullable(map["fullAddress"] as String?),
    username: map["username"] as String,
    email: decryptedEmail,
    dateOfBirth: DateTime.parse(decryptedDateOfBirth),
    role: UserPermissionSerialization.fromCode(map["role"]),
    createdAt: DateTime.parse(map["createdAt"] as String),
  );
}

Future<Map<String, dynamic>> rotateLocalUserPiiFields(
  Map<String, dynamic> map, {
  required UserPiiCipher cipher,
}) async {
  final decryptedEmail = await cipher.decryptNullable(map["email"] as String?);
  final decryptedDateOfBirth = await cipher.decryptNullable(
    map["dateOfBirth"] as String?,
  );
  if (decryptedEmail == null || decryptedDateOfBirth == null) {
    throw const FormatException(
      'Missing required encrypted user fields for rotation.',
    );
  }
  final decryptedPostalCode = await cipher.decryptNullable(
    map["postalCode"] as String?,
  );
  final decryptedFullAddress = await cipher.decryptNullable(
    map["fullAddress"] as String?,
  );

  return {
    ...map,
    "email": await cipher.encryptNullable(decryptedEmail),
    "dateOfBirth": await cipher.encryptNullable(decryptedDateOfBirth),
    "postalCode": await cipher.encryptNullable(decryptedPostalCode),
    "fullAddress": await cipher.encryptNullable(decryptedFullAddress),
  };
}
