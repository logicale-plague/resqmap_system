import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
        stationId TEXT,
        ageGroup INTEGER NOT NULL,
        medicalCondition INTEGER NOT NULL,
        registeredAt TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create Evacuation Centers table
    await db.execute('''
      CREATE TABLE evacuation_centers(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        commandCenterId TEXT NOT NULL,
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

    // Create Stations table
    await db.execute('''
      CREATE TABLE stations(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        evacuationCenterId TEXT NOT NULL,
        capacity INTEGER NOT NULL DEFAULT 0,
        allowedAgeGroup INTEGER,
        allowedMedicalCondition INTEGER,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stations_evacuationCenterId ON stations(evacuationCenterId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_evacuees_stationId ON evacuees(stationId)',
    );

    // Create Supplies table
    await db.execute('''
      CREATE TABLE supplies(
        id TEXT PRIMARY KEY,
        evacuationCenterId TEXT NOT NULL,
        name TEXT NOT NULL,
        currentStock INTEGER NOT NULL,
        usageRatePerDay INTEGER NOT NULL,
        lastRestocked TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_supplies_evacuationCenterId ON supplies(evacuationCenterId)',
    );

    // Create app settings table
    await db.execute('''
      CREATE TABLE app_settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings(
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
  }

  // Future<void> _backfillCenterOccupancy(Database db) async {
  //   await db.transaction((txn) async {
  //     final centers = await txn.query('evacuation_centers', columns: ['id']);
  //     for (final row in centers) {
  //       final centerId = row['id'] as String;
  //       final capacityResult = await txn.rawQuery(
  //         'SELECT COALESCE(SUM(capacity), 0) as totalCapacity FROM stations WHERE evacuationCenterId = ?',
  //         [centerId],
  //       );
  //       final totalCapacity =
  //           (capacityResult.first['totalCapacity'] as num?)?.toInt() ?? 0;
  //       final occupancyResult = await txn.rawQuery(
  //         'SELECT COUNT(*) as count '
  //         'FROM evacuees '
  //         'INNER JOIN stations ON stations.id = evacuees.stationId '
  //         'WHERE stations.evacuationCenterId = ? AND evacuees.active = 1',
  //         [centerId],
  //       );
  //       final currentOccupancy = int.parse(
  //         occupancyResult.first['count'].toString(),
  //       );
  //       final statusIndex = _calculateStatusIndex(
  //         currentOccupancy,
  //         totalCapacity,
  //       );

  //       await txn.update(
  //         'evacuation_centers',
  //         {
  //           'totalCapacity': totalCapacity,
  //           'currentOccupancy': currentOccupancy,
  //           'status': statusIndex,
  //           'lastUpdated': DateTime.now().toIso8601String(),
  //           'synced': 0,
  //         },
  //         where: 'id = ?',
  //         whereArgs: [centerId],
  //       );
  //     }
  //   });
  // }

  Future<void> markAllDataUnsynced() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('evacuation_centers', {'synced': 0});
      await txn.update('stations', {'synced': 0});
      await txn.update('evacuees', {'synced': 0});
      await txn.update('supplies', {'synced': 0});
    });
  }

  // int _calculateStatusIndex(int currentOccupancy, int totalCapacity) {
  //   if (totalCapacity <= 0) {
  //     return 0;
  //   }
  //   final percentage = (currentOccupancy / totalCapacity * 100);
  //   if (percentage >= 100) return 2;
  //   if (percentage >= 80) return 1;
  //   return 0;
  // }
}
