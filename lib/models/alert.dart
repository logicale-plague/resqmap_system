enum AlertSeverity { info, warning, urgent }

class Alert {
  final String id;
  final String message;
  final AlertSeverity severity;
  final DateTime createdAt;
  final bool read;
  final bool synced;

  const Alert({
    required this.id,
    required this.message,
    required this.severity,
    required this.createdAt,
    this.read = false,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'severity': severity.index,
      'createdAt': createdAt.toIso8601String(),
      'read': read ? 1 : 0,
      'synced': synced ? 1 : 0,
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'] as String,
      message: map['message'] as String,
      severity: AlertSeverity.values[map['severity'] as int],
      createdAt: DateTime.parse(map['createdAt'] as String),
      read: (map['read'] as int) == 1,
      synced: map.containsKey('synced') ? (map['synced'] as int) == 1 : false,
    );
  }

  Alert copyWith({
    String? id,
    String? message,
    AlertSeverity? severity,
    DateTime? createdAt,
    bool? read,
    bool? synced,
  }) {
    return Alert(
      id: id ?? this.id,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      synced: synced ?? this.synced,
    );
  }

  @override
  String toString() => 'Alert(id: $id, severity: $severity, message: $message)';
}
