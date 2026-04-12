class UserToEvacCenter {
  final String id;
  final String userId;
  final String centerId;

  UserToEvacCenter({
    required this.id,
    required this.userId,
    required this.centerId,
  });

  UserToEvacCenter copyWith({String? id, String? userId, String? centerId}) {
    return UserToEvacCenter(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      centerId: centerId ?? this.centerId,
    );
  }

  @override
  String toString() =>
      'UserToEvacCenter(id: $id, userId: $userId, evacuationCenterId: $centerId)';
}
