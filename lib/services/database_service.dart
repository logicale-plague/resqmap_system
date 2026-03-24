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
      version: 7,
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

    // Create Alerts table
    await db.execute('''
      CREATE TABLE alerts(
        id TEXT PRIMARY KEY,
        evacuationCenterId TEXT NOT NULL,
        message TEXT NOT NULL,
        severity INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        read INTEGER NOT NULL DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_alerts_evacuationCenterId ON alerts(evacuationCenterId)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE alerts ADD COLUMN synced INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (oldVersion < 3) {
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
      await db.execute('ALTER TABLE evacuees ADD COLUMN stationId TEXT');
    }

    if (oldVersion >= 3 && oldVersion < 4) {
      await db.execute(
        'ALTER TABLE stations ADD COLUMN capacity INTEGER NOT NULL DEFAULT 0',
      );

      final centers = await db.query('evacuation_centers', columns: ['id']);
      for (final row in centers) {
        final centerId = row['id'] as String;
        final capacityResult = await db.rawQuery(
          'SELECT COALESCE(SUM(capacity), 0) as totalCapacity FROM stations WHERE evacuationCenterId = ?',
          [centerId],
        );
        final totalCapacity =
            (capacityResult.first['totalCapacity'] as num?)?.toInt() ?? 0;
        final occupancyResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM evacuees',
        );
        final currentOccupancy = int.parse(
          occupancyResult.first['count'].toString(),
        );
        final statusIndex = _calculateStatusIndex(
          currentOccupancy,
          totalCapacity,
        );

        await db.update(
          'evacuation_centers',
          {
            'totalCapacity': totalCapacity,
            'status': statusIndex,
            'lastUpdated': DateTime.now().toIso8601String(),
            'synced': 0,
          },
          where: 'id = ?',
          whereArgs: [centerId],
        );
      }
    }

    if (oldVersion < 5) {
      await db.execute(
        "ALTER TABLE evacuation_centers ADD COLUMN commandCenterId TEXT NOT NULL DEFAULT 'default-command-center'",
      );
    }

    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE supplies ADD COLUMN evacuationCenterId TEXT',
      );
      await db.execute('ALTER TABLE alerts ADD COLUMN evacuationCenterId TEXT');

      final centerRows = await db.query(
        'evacuation_centers',
        columns: ['id'],
        limit: 1,
      );
      final fallbackCenterId = centerRows.isNotEmpty
          ? centerRows.first['id'] as String
          : 'default-center';

      await db.update(
        'supplies',
        {'evacuationCenterId': fallbackCenterId, 'synced': 0},
        where: 'evacuationCenterId IS NULL OR evacuationCenterId = ?',
        whereArgs: [''],
      );
      await db.update(
        'alerts',
        {'evacuationCenterId': fallbackCenterId, 'synced': 0},
        where: 'evacuationCenterId IS NULL OR evacuationCenterId = ?',
        whereArgs: [''],
      );

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_supplies_evacuationCenterId ON supplies(evacuationCenterId)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_alerts_evacuationCenterId ON alerts(evacuationCenterId)',
      );
    }

    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE evacuees ADD COLUMN active INTEGER NOT NULL DEFAULT 1',
      );
    }
  }

  Future<void> markAllDataUnsynced() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('evacuation_centers', {'synced': 0});
      await txn.update('stations', {'synced': 0});
      await txn.update('evacuees', {'synced': 0});
      await txn.update('supplies', {'synced': 0});
      await txn.update('alerts', {'synced': 0});
    });
  }

  int _calculateStatusIndex(int currentOccupancy, int totalCapacity) {
    if (totalCapacity <= 0) {
      return 0;
    }
    final percentage = (currentOccupancy / totalCapacity * 100);
    if (percentage >= 100) return 2;
    if (percentage >= 80) return 1;
    return 0;
  }
}
