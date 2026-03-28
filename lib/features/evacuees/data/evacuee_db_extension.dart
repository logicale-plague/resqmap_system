import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/evacuees/data/evacuee_dto.dart';
import 'package:kalig_onan_evac_system/features/evacuees/domain/evacuee.dart';
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

  Future<List<Evacuee>> getEvacueesByStation(String stationId) async {
    final db = await database;
    final maps = await db.query(
      'evacuees',
      where: 'stationId = ? AND active = 1',
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

  Future<void> unassignEvacueesFromStation(String stationId) async {
    final db = await database;
    await db.update(
      'evacuees',
      {'stationId': null, 'synced': 0},
      where: 'stationId = ?',
      whereArgs: [stationId],
    );
  }

  Future<List<Evacuee>> getUnsyncedEvacuees() async {
    final db = await database;
    final maps = await db.query('evacuees', where: 'synced = 0');
    return [for (final map in maps) evacueeFromRow(map)];
  }

  Future<void> markEvacueesSynced(List<String> ids) async {
    if (ids.isEmpty) return;

    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final id in ids) {
        batch.update(
          'evacuees',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> replaceEvacueeId(String oldId, String newId) async {
    final db = await database;
    await db.transaction((txn) async {
      final sourceRows = await txn.query(
        'evacuees',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [oldId],
        limit: 1,
      );
      if (sourceRows.isEmpty) {
        final targetRows = await txn.query(
          'evacuees',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [newId],
          limit: 1,
        );
        if (targetRows.isNotEmpty) return;
        throw StateError(
          'replaceEvacueeId could not find sourceId=$oldId or targetId=$newId.',
        );
      }
      if (oldId != newId) {
        await txn.delete('evacuees', where: 'id = ?', whereArgs: [newId]);
      }

      final updated = await txn.update(
        'evacuees',
        {'id': newId, 'synced': 0},
        where: 'id = ?',
        whereArgs: [oldId],
      );

      if (updated != 1) {
        throw StateError(
          'replaceEvacueeId expected to update 1 row for oldId=$oldId, but updated $updated rows.',
        );
      }
    });
  }
}
