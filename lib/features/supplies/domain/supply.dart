class Supply {
  final String id;
  final String evacuationCenterId;
  final String name;
  final int currentStock;
  final int usageRatePerDay;
  final DateTime lastRestocked;
  final bool synced;

  const Supply({
    required this.id,
    required this.evacuationCenterId,
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

  Supply copyWith({
    String? id,
    String? evacuationCenterId,
    String? name,
    int? currentStock,
    int? usageRatePerDay,
    DateTime? lastRestocked,
    bool? synced,
  }) {
    return Supply(
      id: id ?? this.id,
      evacuationCenterId: evacuationCenterId ?? this.evacuationCenterId,
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
