enum CenterStatus { operational, nearCapacity, atCapacity, closed }

class EvacuationCenter {
  final String id;
  final String name;
  final String commandCenterId;
  final double latitude;
  final double longitude;
  final int totalCapacity;
  final int currentOccupancy;
  final CenterStatus status;
  final bool medicalAvailable;
  final DateTime lastUpdated;
  final bool synced;

  const EvacuationCenter({
    required this.id,
    required this.name,
    required this.commandCenterId,
    required this.latitude,
    required this.longitude,
    required this.totalCapacity,
    required this.currentOccupancy,
    required this.status,
    this.medicalAvailable = false,
    required this.lastUpdated,
    this.synced = false,
  });

  double get occupancyPercentage => totalCapacity == 0
      ? 0
      : (currentOccupancy / totalCapacity * 100).clamp(0, 100);

  int get availableSpaces =>
      (totalCapacity - currentOccupancy).clamp(0, totalCapacity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'commandCenterId': commandCenterId,
      'latitude': latitude,
      'longitude': longitude,
      'totalCapacity': totalCapacity,
      'currentOccupancy': currentOccupancy,
      'status': status.index,
      'medicalAvailable': medicalAvailable ? 1 : 0,
      'lastUpdated': lastUpdated.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory EvacuationCenter.fromMap(Map<String, dynamic> map) {
    return EvacuationCenter(
      id: map['id'] as String,
      name: map['name'] as String,
      commandCenterId:
          map['commandCenterId'] as String? ??
          map['commandcenterid'] as String? ??
          map['command_center_id'] as String? ??
          'default-command-center',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      totalCapacity: map['totalCapacity'] as int,
      currentOccupancy: map['currentOccupancy'] as int,
      status: CenterStatus.values[map['status'] as int],
      medicalAvailable: (map['medicalAvailable'] as int) == 1,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      synced: (map['synced'] as int) == 1,
    );
  }

  EvacuationCenter copyWith({
    String? id,
    String? name,
    String? commandCenterId,
    double? latitude,
    double? longitude,
    int? totalCapacity,
    int? currentOccupancy,
    CenterStatus? status,
    bool? medicalAvailable,
    DateTime? lastUpdated,
    bool? synced,
  }) {
    return EvacuationCenter(
      id: id ?? this.id,
      name: name ?? this.name,
      commandCenterId: commandCenterId ?? this.commandCenterId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      currentOccupancy: currentOccupancy ?? this.currentOccupancy,
      status: status ?? this.status,
      medicalAvailable: medicalAvailable ?? this.medicalAvailable,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      synced: synced ?? this.synced,
    );
  }

  @override
  String toString() =>
      'EvacuationCenter(id: $id, name: $name, commandCenterId: $commandCenterId, occupancy: $currentOccupancy/$totalCapacity)';
}
