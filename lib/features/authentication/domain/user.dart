enum UserPermission { admin, staff, user }

class User {
  final String id;
  final double? latitude;
  final double? longitude;
  final String? postalCode;
  final String? fullAddress;
  final String username;
  final String email;
  final DateTime dateOfBirth;
  final UserPermission role;
  final DateTime createdAt;

  const User({
    required this.id,
    this.latitude,
    this.longitude,
    this.postalCode,
    this.fullAddress,
    required this.username,
    required this.email,
    required this.dateOfBirth,
    this.role = UserPermission.user,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? postalCode,
    String? fullAddress,
    String? username,
    String? email,
    DateTime? dateOfBirth,
    UserPermission? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      postalCode: postalCode ?? this.postalCode,
      fullAddress: fullAddress ?? this.fullAddress,
      username: username ?? this.username,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'User(id: $id, username: $username, email: $email, role: $role)';
}
