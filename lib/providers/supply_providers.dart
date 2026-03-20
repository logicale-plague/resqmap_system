import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supply.dart';
import 'database_provider.dart';

final allSuppliesProvider = FutureProvider<List<Supply>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAllSupplies();
});

final unsyncedSuppliesProvider = FutureProvider<List<Supply>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getUnsyncedSupplies();
});

final supplyProvider = FutureProvider.family<Supply?, String>((ref, id) async {
  final db = ref.watch(databaseServiceProvider);
  final supplies = await db.getAllSupplies();
  try {
    return supplies.firstWhere((s) => s.id == id);
  } catch (e) {
    return null;
  }
});

final lowStockSuppliesProvider = FutureProvider<List<Supply>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final supplies = await db.getAllSupplies();
  return supplies
      .where((s) => s.currentStock < (s.usageRatePerDay * 7))
      .toList();
});
