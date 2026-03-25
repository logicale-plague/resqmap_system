class CommandCenter {
  final String id;
  final String name;
  final String? region;
  final String? address;
  final String? contactNumber;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommandCenter({
    required this.id,
    required this.name,
    this.region,
    this.address,
    this.contactNumber,
    this.email,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'address': address,
      'contactNumber': contactNumber,
      'email': email,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CommandCenter.fromMap(Map<String, dynamic> map) {
    return CommandCenter(
      id: map['id'] as String,
      name: map['name'] as String,
      region: map['region'] as String?,
      address: map['address'] as String?,
      contactNumber: map['contactNumber'] as String?,
      email: map['email'] as String?,
      isActive: (map['isActive'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  CommandCenter copyWith({
    String? id,
    String? name,
    String? region,
    String? address,
    String? contactNumber,
    String? email,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommandCenter(
      id: id ?? this.id,
      name: name ?? this.name,
      region: region ?? this.region,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'CommandCenter(id: $id, name: $name, region: $region)';
}
