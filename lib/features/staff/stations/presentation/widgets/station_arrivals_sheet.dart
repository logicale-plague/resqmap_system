import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/widgets/app_list_item_card.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/application/update_evacuee.dart';
import 'package:kalig_onan_evac_system/features/staff/evacuees/presentation/providers/evacuee_providers.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/presentation/widgets/inline_rename_card.dart';
import 'package:kalig_onan_evac_system/features/staff/stations/presentation/widgets/stations_widgets.dart';
import 'package:kalig_onan_evac_system/features/staff/sync/application/sync_service.dart';

import '../../../../../core/indices/models_index.dart';

import '../../../../../core/widgets/app_state/index.dart';

class StationArrivalsSheetContent extends ConsumerWidget {
  final Station station;
  final ScrollController controller;
  final ValueNotifier<String?> editingIdNotifier;

  const StationArrivalsSheetContent({
    super.key,
    required this.station,
    required this.controller,
    required this.editingIdNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unnamedAsync = ref.watch(
      unnamedEvacueesByStationProvider(station.id),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${station.name} - Unnamed Arrivals',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: unnamedAsync.when(
              data: (evacuees) => _buildUnnamedArrivalsList(
                context,
                ref,
                station,
                evacuees,
                controller,
                editingIdNotifier,
              ),
              loading: () => const AppLoadingState(),
              error: (err, stack) =>
                  AppErrorState(error: err, stackTrace: stack),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildUnnamedArrivalsList(
  BuildContext context,
  WidgetRef ref,
  Station station,
  List<Evacuee> evacuees,
  ScrollController controller,
  ValueNotifier<String?> editingIdNotifier,
) {
  if (evacuees.isEmpty) {
    return const Center(child: Text('No unnamed evacuees in this station.'));
  }

  return ValueListenableBuilder<String?>(
    valueListenable: editingIdNotifier,
    builder: (context, editingId, _) {
      final editingIndex = editingId == null
          ? -1
          : evacuees.indexWhere((e) => e.id == editingId);

      return ListView.builder(
        controller: controller,
        itemCount: evacuees.length,
        itemBuilder: (context, index) {
          final evacuee = evacuees[index];
          final isEditing = evacuee.id == editingId;

          if (isEditing) {
            return InlineRenameCard(
              evacuee: evacuee,
              index: editingIndex >= 0 ? editingIndex : index,
              onSave: (name) async {
                await _renameEvacueeAndRefresh(
                  context,
                  ref,
                  station,
                  evacuees,
                  editingIdNotifier,
                  name,
                );
              },
              onCancel: () {
                editingIdNotifier.value = null;
              },
            );
          }

          return _buildArrivalCard(evacuee, index, editingIdNotifier);
        },
      );
    },
  );
}

Widget _buildArrivalCard(
  Evacuee evacuee,
  int index,
  ValueNotifier<String?> editingIdNotifier,
) {
  return AppListItemCard(
    margin: const EdgeInsets.only(bottom: 8),
    title: Text('Arrival ${index + 1}'),
    subtitle: Text(
      '${ageLabel(evacuee.ageGroup)} | ${medicalLabel(evacuee.medicalCondition)}',
    ),
    trailing: TextButton(
      onPressed: () {
        editingIdNotifier.value = evacuee.id;
      },
      child: const Text('Register Name'),
    ),
  );
}

Future<void> _renameEvacueeAndRefresh(
  BuildContext context,
  WidgetRef ref,
  Station station,
  List<Evacuee> evacuees,
  ValueNotifier<String?> editingIdNotifier,
  String name,
) async {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name.')),
      );
    }
    return;
  }

  final currentEditingId = editingIdNotifier.value;
  if (currentEditingId == null) {
    return;
  }

  final currentIndex = evacuees.indexWhere((e) => e.id == currentEditingId);
  if (currentIndex < 0) {
    editingIdNotifier.value = null;
    return;
  }

  final targetEvacuee = evacuees[currentIndex];

  try {
    final updateEvacueeUseCase = ref.read(updateEvacueeProvider);
    await updateEvacueeUseCase.updateEvacueeName(
      evacueeId: targetEvacuee.id,
      name: trimmedName,
    );

    ref.invalidate(unnamedEvacueesByStationProvider(station.id));
    final syncService = ref.read(syncServiceProvider);
    unawaited(syncService.syncNow());
    editingIdNotifier.value = null;
  } catch (e, stackTrace) {
    debugPrint('Rename evacuee failed: $e\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error updating: $e')));
  }
}
