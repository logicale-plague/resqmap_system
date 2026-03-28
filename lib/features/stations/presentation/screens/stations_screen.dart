import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kalig_onan_evac_system/core/indices/models_index.dart';
import 'package:kalig_onan_evac_system/core/indices/provider_index.dart';
import 'package:kalig_onan_evac_system/core/widgets/index.dart';
import 'package:kalig_onan_evac_system/features/stations/presentation/widgets/stations_widgets.dart';

class StationsScreen extends ConsumerWidget {
  const StationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centerAsync = ref.watch(currentCenterProvider);

    return Scaffold(
      appBar: buildScreenAppBar(title: 'Stations Management'),
      body: AsyncDataBuilder<EvacuationCenter?>(
        asyncValue: centerAsync,
        errorPrefix: 'Error loading center',
        builder: (center) {
          if (center == null) {
            return const AppEmptyState(
              icon: Icons.home_work_outlined,
              message: 'No evacuation center assigned',
            );
          }

          final stationsAsync = ref.watch(stationsByCenterProvider(center.id));
          return AsyncDataBuilder<List<Station>>(
            asyncValue: stationsAsync,
            errorPrefix: 'Error loading stations',
            builder: (stations) {
              if (stations.isEmpty) {
                return AppEmptyState(
                  icon: Icons.meeting_room,
                  message: 'No stations created yet',
                  action: ElevatedButton.icon(
                    onPressed: () => openStationDialog(context, ref, center),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Station'),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: stations.length,
                itemBuilder: (context, index) {
                  final station = stations[index];
                  final occupancyAsync = ref.watch(
                    evacueeCountByStationProvider(station.id),
                  );
                  final occupancyCount = occupancyAsync.asData?.value ?? 0;
                  final occupancyColor = occupancyChipColor(
                    occupancyCount,
                    station.capacity,
                  );
                  final unnamedAsync = ref.watch(
                    unnamedEvacueesByStationProvider(station.id),
                  );
                  final unnamedCount = unnamedAsync.asData?.value.length ?? 0;

                  return AppListItemCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    contentPadding: const EdgeInsets.all(14),
                    isThreeLine: true,
                    onTap: () =>
                        openStationArrivalsSheet(context, ref, station),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.meeting_room, color: Colors.white),
                    ),
                    title: Text(
                      station.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AppTagChip(
                            label: 'Cap: ${station.capacity}',
                            color: Colors.green[100]!,
                          ),
                          AppTagChip(
                            label: '$occupancyCount / ${station.capacity}',
                            color: occupancyColor.withAlpha(60),
                          ),
                          AppTagChip(
                            label: ageLabel(station.allowedAgeGroup),
                            color: Colors.blue[100]!,
                          ),
                          AppTagChip(
                            label: medicalLabel(
                              station.allowedMedicalCondition,
                            ),
                            color: Colors.orange[100]!,
                          ),
                          AppTagChip(
                            label: 'Unnamed: $unnamedCount',
                            color: Colors.red[100]!,
                          ),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          openStationDialog(
                            context,
                            ref,
                            center,
                            station: station,
                          );
                        } else if (value == 'delete') {
                          openConfirmDelete(context, ref, station);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: centerAsync.asData?.value == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  openStationDialog(context, ref, centerAsync.asData!.value!),
              icon: const Icon(Icons.add),
              label: const Text('Add Station'),
            ),
    );
  }
}
