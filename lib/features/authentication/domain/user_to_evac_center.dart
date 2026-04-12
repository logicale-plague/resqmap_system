class UserToEvacCenter {
  final String id;
  final String userId;
  final String centerId;
  final bool active;

  UserToEvacCenter({
    required this.id,
    required this.userId,
    required this.centerId,
    required this.active,
  });

  UserToEvacCenter copyWith({
    String? id,
    String? userId,
    String? centerId,
    bool? active,
  }) {
    return UserToEvacCenter(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      centerId: centerId ?? this.centerId,
      active: active ?? this.active,
    );
  }

  @override
  String toString() =>
      'UserToEvacCenter(id: $id, userId: $userId, evacuationCenterId: $centerId, active: $active)';
}
