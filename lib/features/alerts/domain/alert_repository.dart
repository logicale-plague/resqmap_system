import 'package:kalig_onan_evac_system/features/alerts/data/alert.dart';

abstract interface class AlertRepository {
  Future<List<Alert>> getByCenterId(String centerId);
  Future<List<Alert>> getAll();
  Future<Alert?> getById(String id);
  Future<List<Alert>> getUnread(String centerId);
  Future<List<Alert>> getUrgent(String centerId);
  Future<List<Alert>> getUnsynced();
  Future<void> insert(Alert alert);
  Future<void> markRead(String id);
  Future<void> upsertFromRemote(Alert alert);
  Future<void> markSynced(List<String> ids);
  Future<void> replaceId(String oldId, String newId);
}
