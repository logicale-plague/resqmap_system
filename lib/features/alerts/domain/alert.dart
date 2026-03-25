enum AlertSeverity { info, warning, urgent }

class Alert {
  final String id;
  final String evacuationCenterId;
  final String message;
  final AlertSeverity severity;
  final DateTime createdAt;
  final bool read;
  final bool synced;

  const Alert({
    required this.id,
    required this.evacuationCenterId,
    required this.message,
    required this.severity,
    required this.createdAt,
    this.read = false,
    this.synced = false,
  });

  Alert copyWith({
    String? id,
    String? evacuationCenterId,
    String? message,
    AlertSeverity? severity,
    DateTime? createdAt,
    bool? read,
    bool? synced,
  }) {
    return Alert(
      id: id ?? this.id,
      evacuationCenterId: evacuationCenterId ?? this.evacuationCenterId,
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
