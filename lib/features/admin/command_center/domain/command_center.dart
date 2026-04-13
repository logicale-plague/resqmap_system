class CommandCenter {
  final String id;
  final String name;
  final String? region;
  final String? address;
  final String? contactNumber;
  final String? creatorId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String postalCode;

  const CommandCenter({
    required this.id,
    required this.name,
    this.region,
    this.address,
    this.contactNumber,
    this.creatorId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.postalCode,
  });

  CommandCenter copyWith({
    String? id,
    String? name,
    String? region,
    String? address,
    String? contactNumber,
    String? creatorId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? postalCode,
  }) {
    return CommandCenter(
      id: id ?? this.id,
      name: name ?? this.name,
      region: region ?? this.region,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      creatorId: creatorId ?? this.creatorId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  @override
  String toString() =>
      'CommandCenter(id: $id, name: $name, region: $region, creatorId: $creatorId, postalCode: $postalCode)';
}
