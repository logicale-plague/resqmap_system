class UserToCmdCenter {
  final String id;
  final String userId;
  final String cmdCenterId;

  const UserToCmdCenter({
    required this.id,
    required this.userId,
    required this.cmdCenterId,
  });

  factory UserToCmdCenter.fromMap(Map<String, dynamic> map) {
    return UserToCmdCenter(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      cmdCenterId: map['cmd_center_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'user_id': userId, 'cmd_center_id': cmdCenterId};
  }

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
