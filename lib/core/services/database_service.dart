import 'package:flutter/foundation.dart';
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
    if (kDebugMode) {
      Sqflite.devSetDebugModeOn(true);
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'kalig_onan_evac.db');

    return openDatabase(
      path,
      version: 11,
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
        gender TEXT NOT NULL DEFAULT 'Unspecified',
        address TEXT,
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
        fullAddress TEXT,
        postalCode TEXT,
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
        active INTEGER NOT NULL DEFAULT 1,
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

    // Create users table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT NOT NULL,
        dateOfBirth TEXT NOT NULL,
        passwordHash TEXT,
        role TEXT NOT NULL DEFAULT 'user',
        latitude REAL,
        longitude REAL,
        postalCode TEXT,
        fullAddress TEXT,
        emailHash TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_users_emailHash ON users(emailHash)',
    );

    await _createUserCommandCentersTable(db);
    await _createUserEvacCentersTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings(
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

      // Seed currentCenterId so getCurrentCenter() won't return null after
      // migrating from v1. Pick the row with the most-recent lastUpdated as
      // the sensible default; only insert when the key isn't already present.
      final existing = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['currentCenterId'],
        limit: 1,
      );
      if (existing.isEmpty) {
        final centers = await db.query(
          'evacuation_centers',
          columns: ['id'],
          orderBy: 'lastUpdated DESC',
          limit: 1,
        );
        if (centers.isNotEmpty) {
          await db.insert('app_settings', {
            'key': 'currentCenterId',
            'value': centers.first['id'] as String,
          });
        }
      }
    }

    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE stations ADD COLUMN active INTEGER NOT NULL DEFAULT 1
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users(
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL,
          email TEXT NOT NULL,
          dateOfBirth TEXT NOT NULL,
          role INTEGER NOT NULL DEFAULT 2,
          latitude REAL,
          longitude REAL,
          postalCode TEXT,
          fullAddress TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 5) {
      await db.execute('''
        ALTER TABLE users ADD COLUMN passwordHash TEXT
      ''');
    }

    if (oldVersion < 6) {
      final usersTableExists = await _tableExists(db, 'users');
      if (usersTableExists) {
        await db.execute('ALTER TABLE users RENAME TO users_legacy_v5');

        await db.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            username TEXT NOT NULL,
            email TEXT NOT NULL,
            dateOfBirth TEXT NOT NULL,
            passwordHash TEXT,
            role TEXT NOT NULL DEFAULT 'user',
            latitude REAL,
            longitude REAL,
            postalCode TEXT,
            fullAddress TEXT,
            emailHash TEXT,
            createdAt TEXT NOT NULL
          )
        ''');

        final legacyHasPasswordHash = await _columnExists(
          db,
          table: 'users_legacy_v5',
          column: 'passwordHash',
        );
        final legacyHasEmailHash = await _columnExists(
          db,
          table: 'users_legacy_v5',
          column: 'emailHash',
        );
        final passwordHashExpr = legacyHasPasswordHash
            ? 'passwordHash'
            : 'NULL AS passwordHash';
        final emailHashExpr = legacyHasEmailHash
            ? 'emailHash'
            : 'NULL AS emailHash';

        await db.execute('''
          INSERT INTO users (
            id,
            username,
            email,
            dateOfBirth,
            passwordHash,
            role,
            latitude,
            longitude,
            postalCode,
            fullAddress,
            emailHash,
            createdAt
          )
          SELECT
            id,
            username,
            email,
            dateOfBirth,
            $passwordHashExpr,
            CASE
              WHEN typeof(role) = 'integer' THEN
                CASE role
                  WHEN 0 THEN 'admin'
                  WHEN 1 THEN 'staff'
                  ELSE 'user'
                END
              WHEN role IN ('admin', 'staff', 'user') THEN role
              ELSE 'user'
            END AS role,
            latitude,
            longitude,
            postalCode,
            fullAddress,
            $emailHashExpr,
            createdAt
          FROM users_legacy_v5
        ''');

        await db.execute('DROP TABLE users_legacy_v5');
      } else {
        await db.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            username TEXT NOT NULL,
            email TEXT NOT NULL,
            dateOfBirth TEXT NOT NULL,
            passwordHash TEXT,
            role TEXT NOT NULL DEFAULT 'user',
            latitude REAL,
            longitude REAL,
            postalCode TEXT,
            fullAddress TEXT,
            emailHash TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
      }

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_users_emailHash ON users(emailHash)',
      );
    }

    if (oldVersion < 7) {
      // Add postalCode to command_centers table
      final centerTableExists = await _tableExists(db, 'command_centers');
      if (centerTableExists) {
        final hasPostalCode = await _columnExists(
          db,
          table: 'command_centers',
          column: 'postalCode',
        );
        if (!hasPostalCode) {
          await db.execute(
            'ALTER TABLE command_centers ADD COLUMN postalCode TEXT',
          );
        }
      }
    }

    if (oldVersion < 8) {
      await _createUserCommandCentersTable(db);
    }

    if (oldVersion < 9) {
      await _createUserEvacCentersTable(db);
    }

    if (oldVersion < 10) {
      final userCmdCentersExists = await _tableExists(db, 'user_cmd_centers');
      if (userCmdCentersExists) {
        final hasActive = await _columnExists(
          db,
          table: 'user_cmd_centers',
          column: 'active',
        );
        if (!hasActive) {
          await db.execute(
            'ALTER TABLE user_cmd_centers ADD COLUMN active INTEGER NOT NULL DEFAULT 1',
          );
        }
      }

      final userEvacCentersExists = await _tableExists(db, 'user_evac_centers');
      if (userEvacCentersExists) {
        final hasActive = await _columnExists(
          db,
          table: 'user_evac_centers',
          column: 'active',
        );
        if (!hasActive) {
          await db.execute(
            'ALTER TABLE user_evac_centers ADD COLUMN active INTEGER NOT NULL DEFAULT 1',
          );
        }
      }
    }

    if (oldVersion < 11) {
      final evacueesExists = await _tableExists(db, 'evacuees');
      if (evacueesExists) {
        final hasGender = await _columnExists(
          db,
          table: 'evacuees',
          column: 'gender',
        );
        if (!hasGender) {
          await db.execute(
            "ALTER TABLE evacuees ADD COLUMN gender TEXT NOT NULL DEFAULT 'Unspecified'",
          );
        }

        final hasAddress = await _columnExists(
          db,
          table: 'evacuees',
          column: 'address',
        );
        if (!hasAddress) {
          await db.execute('ALTER TABLE evacuees ADD COLUMN address TEXT');
        }
      }
    }
  }

  Future<void> _createUserCommandCentersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_cmd_centers(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        commandCenterId TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_user_cmd_centers_userId ON user_cmd_centers(userId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_user_cmd_centers_commandCenterId ON user_cmd_centers(commandCenterId)',
    );
  }

  Future<void> _createUserEvacCentersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_evac_centers(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        evacuationCenterId TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_user_evac_centers_userId ON user_evac_centers(userId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_user_evac_centers_evacuationCenterId ON user_evac_centers(evacuationCenterId)',
    );
  }

  Future<void> insertUserCommandCenterAccessRow({
    required String userId,
    required String commandCenterId,
    bool active = true,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;
    await db.insert('user_cmd_centers', {
      'id': '$userId::$commandCenterId',
      'userId': userId,
      'commandCenterId': commandCenterId,
      'active': active ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertUserEvacCenterAccessRow({
    required String userId,
    required String evacuationCenterId,
    bool active = true,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;
    await db.insert('user_evac_centers', {
      'id': '$userId::$evacuationCenterId',
      'userId': userId,
      'evacuationCenterId': evacuationCenterId,
      'active': active ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> _tableExists(Database db, String table) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [table],
    );
    return rows.isNotEmpty;
  }

  Future<bool> _columnExists(
    Database db, {
    required String table,
    required String column,
  }) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    for (final row in rows) {
      if (row['name'] == column) {
        return true;
      }
    }
    return false;
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
