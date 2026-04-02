import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/features/staff/centers/data/evacuation_center_db_extension.dart';
import 'package:kalig_onan_evac_system/core/services/database_service.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/data/evacuee_dto.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/domain/evacuee.dart';

final updateEvacueeProvider = Provider<UpdateEvacueeUseCase>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return UpdateEvacueeUseCase(databaseService: dbService);
});

class UpdateEvacueeUseCase {
  final DatabaseService _databaseService;
  static const int _maxAttempts = 3;

  UpdateEvacueeUseCase({required DatabaseService databaseService})
    : _databaseService = databaseService;

  Future<void> updateEvacueeName({
    required String evacueeId,
    required String name,
  }) async {
    final db = await _databaseService.database;
    final evacueeRows = await db.query(
      'evacuees',
      where: 'id = ?',
      whereArgs: [evacueeId],
      limit: 1,
    );

    if (evacueeRows.isEmpty) {
      throw StateError(
        'updateEvacueeName could not find evacueeId=$evacueeId.',
      );
    }

    final existing = evacueeFromRow(evacueeRows.first);
    await updateEvacuee(existing.copyWith(name: name, synced: false));
  }

  Future<void> updateEvacuee(Evacuee evacuee) async {
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      final db = await _databaseService.database;
      final evacueePartialRow = evacueeToPartialRow(evacuee)..['synced'] = 0;
      try {
        await db.transaction((txn) async {
          if (kDebugMode) {
            debugPrint(
              'updateEvacuee: attempt=$attempt id=${evacuee.id} (transactional update)',
            );
          }

          final evacueeRows = await txn.query(
            'evacuees',
            where: 'id = ?',
            whereArgs: [evacuee.id],
            limit: 1,
          );

          if (evacueeRows.isEmpty) {
            throw StateError(
              'updateEvacuee could not find evacueeId=${evacuee.id}.',
            );
          }

          final existing = evacueeFromRow(evacueeRows.first);
          final occupancyAffected =
              existing.stationId != evacuee.stationId ||
              existing.active != evacuee.active;

          if (kDebugMode) {
            debugPrint(
              'updateEvacuee: fetched existing id=${evacuee.id} occupancyAffected=$occupancyAffected',
            );
          }

          await txn.update(
            'evacuees',
            evacueePartialRow,
            where: 'id = ?',
            whereArgs: [evacuee.id],
          );

          if (occupancyAffected) {
            await _databaseService.refreshCurrentCenterOccupancy(executor: txn);
          }
        });
        if (kDebugMode) {
          debugPrint(
            'updateEvacuee: attempt=$attempt id=${evacuee.id} (non-transactional update)',
          );
        }

        final evacueeRows = await db.query(
          'evacuees',
          where: 'id = ?',
          whereArgs: [evacuee.id],
          limit: 1,
        );

        if (evacueeRows.isEmpty) {
          throw StateError(
            'updateEvacuee could not find evacueeId=${evacuee.id}.',
          );
        }

        final existing = evacueeFromRow(evacueeRows.first);
        final occupancyAffected =
            existing.stationId != evacuee.stationId ||
            existing.active != evacuee.active;

        if (kDebugMode) {
          debugPrint(
            'updateEvacuee: fetched existing id=${evacuee.id} occupancyAffected=$occupancyAffected',
          );
        }

        await db.update(
          'evacuees',
          evacueePartialRow,
          where: 'id = ?',
          whereArgs: [evacuee.id],
        );

        if (occupancyAffected) {
          await _databaseService.refreshCurrentCenterOccupancy();
        }

        if (kDebugMode) {
          debugPrint(
            'updateEvacuee: success attempt=$attempt id=${evacuee.id}',
          );
        }
        return;
      } catch (e, stackTrace) {
        final isBusy = _isBusyDatabaseError(e);
        final isLastAttempt = attempt >= _maxAttempts;

        if (kDebugMode) {
          debugPrint(
            'updateEvacuee: failed attempt=$attempt id=${evacuee.id} busy=$isBusy error=$e\n$stackTrace',
          );
        }

        if (!isBusy || isLastAttempt) {
          rethrow;
        }

        await Future<void>.delayed(Duration(milliseconds: 120 * attempt));
      }
    }
  }

  bool _isBusyDatabaseError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('database is locked') ||
        message.contains('database is busy') ||
        message.contains('sql_busy') ||
        message.contains('code 5');
  }
}
