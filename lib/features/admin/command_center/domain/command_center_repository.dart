import 'package:kalig_onan_evac_system/core/indices/models_index.dart';

abstract interface class CommandCenterRepository {
  // READ operations
  Future<CommandCenter?> getCurrent();
  Future<List<CommandCenter>> getAll();
  Future<CommandCenter?> getById(String id);

  // WRITE operations
  Future<void> update(CommandCenter center);
}
