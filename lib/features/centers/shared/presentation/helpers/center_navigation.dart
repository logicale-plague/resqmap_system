import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/data/evacuation_center_db_extension.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/domain/evacuation_center.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/presentation/providers/evacuation_center_providers.dart';

Future<void> openCenterDashboard(
  BuildContext context,
  WidgetRef ref,
  EvacuationCenter center,
) async {
  final db = ref.read(databaseServiceProvider);
  await db.setCurrentCenterId(center.id);
  ref.invalidate(currentCenterProvider);

  if (!context.mounted) return;
  context.push('/dashboard', extra: center);
}
