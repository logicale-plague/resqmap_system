import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/supplies/application/add_supply.dart';
import 'package:kalig_onan_evac_system/features/supplies/application/update_supply.dart';
import 'package:kalig_onan_evac_system/features/supplies/data/supply_db_extension.dart';
import 'package:kalig_onan_evac_system/features/supplies/data/supply_repository_impl.dart';

import 'package:kalig_onan_evac_system/features/supplies/domain/supply.dart';
import 'package:kalig_onan_evac_system/features/supplies/domain/supply_repository.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/features/centers/presentation/providers/evacuation_center_providers.dart';

final supplyRepositoryProvider = Provider<SupplyRepository>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final addSupply = ref.watch(addSupplyProvider);
  final updateSupply = ref.watch(updateSupplyProvider);

  return SupplyRepositoryImpl(
    db,
    addSupply: addSupply,
    updateSupply: updateSupply,
  );
});

final allCenterSuppliesProvider = FutureProvider<List<Supply>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAllSupplies();
});

final allSuppliesProvider = FutureProvider<List<Supply>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final center = await ref.watch(currentCenterProvider.future);
  if (center == null) return [];
  return db.getSuppliesByCenterId(center.id);
});

final unsyncedSuppliesProvider = FutureProvider<List<Supply>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getUnsyncedSupplies();
});

final supplyProvider = FutureProvider.family<Supply?, String>((ref, id) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getSupplyById(id);
});

final lowStockSuppliesProvider = FutureProvider<List<Supply>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final center = await ref.watch(currentCenterProvider.future);
  if (center == null) return [];
  final supplies = await db.getSuppliesByCenterId(center.id);
  return supplies
      .where((s) => s.currentStock < (s.usageRatePerDay * 7))
      .toList();
});

final allLowStockSuppliesProvider = FutureProvider<List<Supply>>((ref) async {
  final supplies = await ref.watch(allCenterSuppliesProvider.future);
  return supplies
      .where((s) => s.currentStock < (s.usageRatePerDay * 7))
      .toList();
});

final lowStockSuppliesByCenterProvider =
    FutureProvider<Map<String, List<Supply>>>((ref) async {
      final lowStockSupplies = await ref.watch(
        allLowStockSuppliesProvider.future,
      );
      final suppliesByCenter = <String, List<Supply>>{};

      for (final supply in lowStockSupplies) {
        suppliesByCenter
            .putIfAbsent(supply.evacuationCenterId, () => <Supply>[])
            .add(supply);
      }

      return suppliesByCenter;
    });
