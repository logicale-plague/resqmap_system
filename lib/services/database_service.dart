import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/index.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'kalig_onan_evac.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Evacuees table
    await db.execute('''
      CREATE TABLE evacuees(
        id TEXT PRIMARY KEY,
        name TEXT,
        ageGroup INTEGER NOT NULL,
        medicalCondition INTEGER NOT NULL,
        registeredAt TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create Evacuation Centers table
    await db.execute('''
      CREATE TABLE evacuation_centers(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        totalCapacity INTEGER NOT NULL,
        currentOccupancy INTEGER NOT NULL,
        status INTEGER NOT NULL,
        medicalAvailable INTEGER NOT NULL DEFAULT 0,
        lastUpdated TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create Supplies table
    await db.execute('''
      CREATE TABLE supplies(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        currentStock INTEGER NOT NULL,
        usageRatePerDay INTEGER NOT NULL,
        lastRestocked TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create Alerts table
    await db.execute('''
      CREATE TABLE alerts(
        id TEXT PRIMARY KEY,
        message TEXT NOT NULL,
        severity INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        read INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE alerts ADD COLUMN synced INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  // Evacuee operations
  Future<void> insertEvacuee(Evacuee evacuee) async {
    final db = await database;
    await db.insert(
      'evacuees',
      evacuee.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _syncCurrentCenterOccupancy();
  }

  Future<List<Evacuee>> getAllEvacuees() async {
    final db = await database;
    final maps = await db.query('evacuees');
    return [for (final map in maps) Evacuee.fromMap(map)];
  }

  Future<int> getEvacueeCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM evacuees');
    return int.parse(result.first['count'].toString());
  }

  Future<Evacuee?> getEvacueeById(String id) async {
    final db = await database;
    final maps = await db.query(
      'evacuees',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : Evacuee.fromMap(maps.first);
  }

  Future<void> upsertEvacueeFromRemote(Evacuee evacuee) async {
    final db = await database;
    await db.insert(
      'evacuees',
      evacuee.copyWith(synced: true).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeEvacuee(String id) async {
    final db = await database;
    await db.delete('evacuees', where: 'id = ?', whereArgs: [id]);
    await _syncCurrentCenterOccupancy();
  }

  Future<List<Evacuee>> getUnsyncedEvacuees() async {
    final db = await database;
    final maps = await db.query('evacuees', where: 'synced = 0');
    return [for (final map in maps) Evacuee.fromMap(map)];
  }

  Future<List<EvacuationCenter>> getUnsyncedCenters() async {
    final db = await database;
    final maps = await db.query('evacuation_centers', where: 'synced = 0');
    return [for (final map in maps) EvacuationCenter.fromMap(map)];
  }

  Future<List<Supply>> getUnsyncedSupplies() async {
    final db = await database;
    final maps = await db.query('supplies', where: 'synced = 0');
    return [for (final map in maps) Supply.fromMap(map)];
  }

  Future<List<Alert>> getUnsyncedAlerts() async {
    final db = await database;
    final maps = await db.query('alerts', where: 'synced = 0');
    return [for (final map in maps) Alert.fromMap(map)];
  }

  Future<void> markEvacueesSynced(List<String> ids) async {
    final db = await database;
    for (final id in ids) {
      await db.update(
        'evacuees',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> markCentersSynced(List<String> ids) async {
    final db = await database;
    for (final id in ids) {
      await db.update(
        'evacuation_centers',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> markSuppliesSynced(List<String> ids) async {
    final db = await database;
    for (final id in ids) {
      await db.update(
        'supplies',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> markAlertsSynced(List<String> ids) async {
    final db = await database;
    for (final id in ids) {
      await db.update(
        'alerts',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Evacuation Center operations
  Future<void> insertEvacuationCenter(EvacuationCenter center) async {
    final db = await database;
    await db.insert(
      'evacuation_centers',
      center.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<EvacuationCenter?> getCurrentCenter() async {
    // In real implementation, this would get the center assigned to the staff member
    // For now, returns the first center (or null if none exist)
    final db = await database;
    final maps = await db.query('evacuation_centers', limit: 1);
    return maps.isEmpty ? null : EvacuationCenter.fromMap(maps.first);
  }

  Future<List<EvacuationCenter>> getAllCenters() async {
    final db = await database;
    final maps = await db.query('evacuation_centers');
    return [for (final map in maps) EvacuationCenter.fromMap(map)];
  }

  Future<EvacuationCenter?> getCenterById(String id) async {
    final db = await database;
    final maps = await db.query(
      'evacuation_centers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : EvacuationCenter.fromMap(maps.first);
  }

  Future<void> upsertCenterFromRemote(EvacuationCenter center) async {
    final db = await database;
    await db.insert(
      'evacuation_centers',
      center.copyWith(synced: true).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCenterOccupancy(String centerId, int newOccupancy) async {
    final db = await database;
    final centerRows = await db.query(
      'evacuation_centers',
      columns: ['totalCapacity'],
      where: 'id = ?',
      whereArgs: [centerId],
      limit: 1,
    );
    if (centerRows.isEmpty) return;

    final totalCapacity = centerRows.first['totalCapacity'] as int;
    final status = _calculateStatus(newOccupancy, totalCapacity);

    await db.update(
      'evacuation_centers',
      {
        'currentOccupancy': newOccupancy,
        'status': status.index,
        'lastUpdated': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [centerId],
    );
  }

  Future<void> replaceCenterId(String oldId, String newId) async {
    final db = await database;
    await db.update(
      'evacuation_centers',
      {
        'id': newId,
        'synced': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [oldId],
    );
  }

  Future<void> _syncCurrentCenterOccupancy() async {
    final db = await database;

    final centerRows = await db.query(
      'evacuation_centers',
      columns: ['id', 'totalCapacity'],
      limit: 1,
    );
    if (centerRows.isEmpty) return;

    final centerId = centerRows.first['id'] as String;
    final totalCapacity = centerRows.first['totalCapacity'] as int;

    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM evacuees',
    );
    final evacueeCount = int.parse(countResult.first['count'].toString());
    final status = _calculateStatus(evacueeCount, totalCapacity);

    await db.update(
      'evacuation_centers',
      {
        'currentOccupancy': evacueeCount,
        'status': status.index,
        'lastUpdated': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [centerId],
    );
  }

  Future<void> refreshCurrentCenterOccupancy() async {
    await _syncCurrentCenterOccupancy();
  }

  // Supply operations
  Future<void> insertSupply(Supply supply) async {
    final db = await database;
    await db.insert(
      'supplies',
      supply.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Supply>> getAllSupplies() async {
    final db = await database;
    final maps = await db.query('supplies');
    return [for (final map in maps) Supply.fromMap(map)];
  }

  Future<Supply?> getSupplyById(String id) async {
    final db = await database;
    final maps = await db.query(
      'supplies',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : Supply.fromMap(maps.first);
  }

  Future<void> upsertSupplyFromRemote(Supply supply) async {
    final db = await database;
    await db.insert(
      'supplies',
      supply.copyWith(synced: true).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceSupplyId(String oldId, String newId) async {
    final db = await database;
    await db.update(
      'supplies',
      {'id': newId, 'synced': 0},
      where: 'id = ?',
      whereArgs: [oldId],
    );
  }

  Future<void> updateSupplyStock(String supplyId, int newStock) async {
    final db = await database;
    await db.update(
      'supplies',
      {'currentStock': newStock, 'synced': 0},
      where: 'id = ?',
      whereArgs: [supplyId],
    );
  }

  // Alert operations
  Future<void> insertAlert(Alert alert) async {
    final db = await database;
    await db.insert(
      'alerts',
      alert.copyWith(synced: false).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Alert>> getAllAlerts() async {
    final db = await database;
    final maps = await db.query('alerts', orderBy: 'createdAt DESC');
    return [for (final map in maps) Alert.fromMap(map)];
  }

  Future<Alert?> getAlertById(String id) async {
    final db = await database;
    final maps = await db.query(
      'alerts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : Alert.fromMap(maps.first);
  }

  Future<void> upsertAlertFromRemote(Alert alert) async {
    final db = await database;
    await db.insert(
      'alerts',
      alert.copyWith(synced: true).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceAlertId(String oldId, String newId) async {
    final db = await database;
    await db.update(
      'alerts',
      {'id': newId, 'synced': 0},
      where: 'id = ?',
      whereArgs: [oldId],
    );
  }

  Future<void> replaceEvacueeId(String oldId, String newId) async {
    final db = await database;
    await db.update(
      'evacuees',
      {'id': newId, 'synced': 0},
      where: 'id = ?',
      whereArgs: [oldId],
    );
  }

  Future<List<Alert>> getUnreadAlerts() async {
    final db = await database;
    final maps = await db.query('alerts', where: 'read = 0');
    return [for (final map in maps) Alert.fromMap(map)];
  }

  Future<void> markAlertAsRead(String alertId) async {
    final db = await database;
    await db.update(
      'alerts',
      {'read': 1, 'synced': 0},
      where: 'id = ?',
      whereArgs: [alertId],
    );
  }

  CenterStatus _calculateStatus(int currentOccupancy, int totalCapacity) {
    final percentage = (currentOccupancy / totalCapacity * 100);
    if (percentage >= 100) return CenterStatus.atCapacity;
    if (percentage >= 80) return CenterStatus.nearCapacity;
    return CenterStatus.operational;
  }
}
