import 'package:kalig_onan_evac_system/features/evacuees/data/evacuee_dto.dart';
import 'package:kalig_onan_evac_system/features/evacuees/domain/evacuee.dart';
import 'package:kalig_onan_evac_system/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

extension EvacueeDatabaseExtensions on DatabaseService {
  Future<List<Evacuee>> getUnnamedEvacueesByStation(String stationId) async {
    final db = await database;
    final maps = await db.query(
      'evacuees',
      where:
          'stationId = ? AND active = 1 AND (name IS NULL OR TRIM(name) = "")',
      whereArgs: [stationId],
      orderBy: 'registeredAt ASC',
    );
    return [for (final map in maps) evacueeFromRow(map)];
  }

  Future<List<Evacuee>> getAllEvacuees({bool includeInactive = false}) async {
    final db = await database;
    final maps = includeInactive
        ? await db.query('evacuees')
        : await db.query('evacuees', where: 'active = 1');
    return [for (final map in maps) evacueeFromRow(map)];
  }

  Future<int> getEvacueeCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM evacuees WHERE active = 1',
    );
    return int.parse(result.first['count'].toString());
  }

  Future<int> getEvacueeCountByStation(String stationId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM evacuees WHERE stationId = ? AND active = 1',
      [stationId],
    );
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
    return maps.isEmpty ? null : evacueeFromRow(maps.first);
  }

  Future<void> upsertEvacueeFromRemote(Evacuee evacuee) async {
    final db = await database;
    await db.insert(
      'evacuees',
      evacueeToRow(evacuee.copyWith(synced: true)),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Evacuee>> getUnsyncedEvacuees() async {
    final db = await database;
    final maps = await db.query('evacuees', where: 'synced = 0');
    return [for (final map in maps) evacueeFromRow(map)];
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

  Future<void> replaceEvacueeId(String oldId, String newId) async {
    final db = await database;
    await db.update(
      'evacuees',
      {'id': newId, 'synced': 0},
      where: 'id = ?',
      whereArgs: [oldId],
    );
  }
}
