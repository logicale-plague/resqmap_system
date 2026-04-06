import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center.dart';

Map<String, dynamic> commandCenterToMap(CommandCenter center) {
  return {
    'id': center.id,
    'name': center.name,
    'region': center.region,
    'address': center.address,
    'contactNumber': center.contactNumber,
    'email': center.email,
    'isActive': center.isActive ? 1 : 0,
    'createdAt': center.createdAt.toIso8601String(),
    'updatedAt': center.updatedAt.toIso8601String(),
    'postalCode': center.postalCode,
  };
}

Map<String, dynamic> commandCenterToRemoteMap(CommandCenter center) {
  return {
    'id': center.id,
    'name': center.name,
    'region': center.region,
    'address': center.address,
    'contact_number': center.contactNumber,
    'email': center.email,
    'is_active': center.isActive ? 1 : 0,
    'created_at': center.createdAt.toIso8601String(),
    'updated_at': center.updatedAt.toIso8601String(),
    'postal_code': center.postalCode,
  };
}

CommandCenter commandCenterFromMap(Map<String, dynamic> map) {
  return CommandCenter(
    id: map['id'] as String,
    name: map['name'] as String,
    region: map['region'] as String?,
    address: map['address'] as String?,
    contactNumber: map['contactNumber'] as String?,
    email: map['email'] as String?,
    isActive: (map['isActive'] as int? ?? 1) == 1,
    createdAt:
        DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
    postalCode: (map['postalCode'] as String? ?? ''),
  );
}

CommandCenter commandCenterFromRemoteMap(Map<String, dynamic> map) {
  return CommandCenter(
    id: map['id'] as String,
    name: map['name'] as String,
    region: map['region'] as String?,
    address: map['address'] as String?,
    contactNumber: map['contact_number'] as String?,
    email: map['email'] as String?,
    isActive: _parseBool(map['is_active']),
    createdAt:
        DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    postalCode: (map['postal_code'] as String? ?? ''),
  );
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 't';
  }
  return false;
}
