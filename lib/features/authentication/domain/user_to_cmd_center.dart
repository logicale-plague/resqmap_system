class UserToCmdCenter {
  final String id;
  final String userId;
  final String cmdCenterId;

  const UserToCmdCenter({
    required this.id,
    required this.userId,
    required this.cmdCenterId,
  });

  UserToCmdCenter copyWith({String? id, String? userId, String? cmdCenterId}) {
    return UserToCmdCenter(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cmdCenterId: cmdCenterId ?? this.cmdCenterId,
    );
  }

  @override
  String toString() =>
      'UserToCmdCenter(id: $id, userId: $userId, cmdCenterId: $cmdCenterId)';
}
