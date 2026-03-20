class Supply {
  final String id;
  final String name;
  final int currentStock;
  final int usageRatePerDay;
  final DateTime lastRestocked;
  final bool synced;

  const Supply({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.usageRatePerDay,
    required this.lastRestocked,
    this.synced = false,
  });

  int get daysRemaining {
    if (usageRatePerDay == 0) return 0;
    return (currentStock / usageRatePerDay).ceil();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currentStock': currentStock,
      'usageRatePerDay': usageRatePerDay,
      'lastRestocked': lastRestocked.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory Supply.fromMap(Map<String, dynamic> map) {
    return Supply(
      id: map['id'] as String,
      name: map['name'] as String,
      currentStock: map['currentStock'] as int,
      usageRatePerDay: map['usageRatePerDay'] as int,
      lastRestocked: DateTime.parse(map['lastRestocked'] as String),
      synced: (map['synced'] as int) == 1,
    );
  }

  Supply copyWith({
    String? id,
    String? name,
    int? currentStock,
    int? usageRatePerDay,
    DateTime? lastRestocked,
    bool? synced,
  }) {
    return Supply(
      id: id ?? this.id,
      name: name ?? this.name,
      currentStock: currentStock ?? this.currentStock,
      usageRatePerDay: usageRatePerDay ?? this.usageRatePerDay,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      synced: synced ?? this.synced,
    );
  }

  @override
  String toString() =>
      'Supply(id: $id, name: $name, stock: $currentStock, remaining: ${daysRemaining}d)';
}
