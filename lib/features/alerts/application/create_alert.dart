import 'package:kalig_onan_evac_system/features/alerts/data/alert_dto.dart';
import 'package:kalig_onan_evac_system/features/alerts/domain/alert.dart';
import 'package:kalig_onan_evac_system/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

extension CreateAlertUseCase on DatabaseService {
  Future<void> insertAlert(Alert alert) async {
    final db = await database;
    await db.insert(
      'alerts',
      alertToRow(alert.copyWith(synced: false)),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
