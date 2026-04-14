import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/indices/provider_index.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/domain/command_center.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/providers/command_center_providers.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/providers/user_provider.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/providers/map_provider.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/widgets/add_evac_sheet.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/index.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/presentation/providers/evacuation_center_providers.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/widgets/add_user_location.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/widgets/evac_info_botsheet.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/widgets/guide_user.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

final commandCenterByIdProvider = FutureProvider.family<CommandCenter?, String>(
  (ref, commandCenterId) async {
    final repository = ref.watch(commandCenterRepositoryProvider);
    return repository.getById(commandCenterId);
  },
);

final staffManagedCommandCentersProvider = FutureProvider<List<CommandCenter>>((
  ref,
) async {
  final assignedCenters = await ref.watch(staffAssignedCentersProvider.future);
  if (assignedCenters.isEmpty) {
    return [];
  }

  final commandCenterIds =
      assignedCenters.map((center) => center.commandCenterId).toSet().toList()
        ..sort();

  final repository = ref.watch(commandCenterRepositoryProvider);
  final commandCenters = <CommandCenter>[];
  for (final commandCenterId in commandCenterIds) {
    final commandCenter = await repository.getById(commandCenterId);
    if (commandCenter != null) {
      commandCenters.add(commandCenter);
    }
  }

  commandCenters.sort((a, b) => a.name.compareTo(b.name));
  return commandCenters;
});

final currentUserPostalCentersProvider = FutureProvider<List<EvacuationCenter>>(
  (ref) async {
    final user = await ref.watch(currentUserProvider.future);
    final postalCode = user?.postalCode?.trim();
    if (postalCode == null || postalCode.isEmpty) {
      return [];
    }

    final centers = await ref.watch(allCentersProvider.future);
    final filtered = centers
        .where((center) => center.postalCode == postalCode)
        .toList();
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  },
);

enum _MapScopeType { commandCenter, postal }

class _MapScopeOption {
  final String id;
  final String label;
  final _MapScopeType type;
  final String? commandCenterId;

  const _MapScopeOption._({
    required this.id,
    required this.label,
    required this.type,
    this.commandCenterId,
  });

  factory _MapScopeOption.commandCenter(CommandCenter commandCenter) {
    return _MapScopeOption._(
      id: 'command-center:${commandCenter.id}',
      label: commandCenter.name,
      type: _MapScopeType.commandCenter,
      commandCenterId: commandCenter.id,
    );
  }

  factory _MapScopeOption.postal() {
    return const _MapScopeOption._(
      id: 'postal',
      label: 'Home location',
      type: _MapScopeType.postal,
    );
  }
}

final mapScopeOptionsProvider = FutureProvider<List<_MapScopeOption>>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    return [];
  }

  final options = <_MapScopeOption>[];

  if (user.role == UserPermission.admin) {
    final commandCenters = await ref.watch(
      assignedCommandCentersProvider.future,
    );
    options.addAll(commandCenters.map(_MapScopeOption.commandCenter));
    if ((user.postalCode?.trim().isNotEmpty ?? false)) {
      options.add(_MapScopeOption.postal());
    }
    return options;
  }

  if (user.role == UserPermission.staff) {
    if ((user.postalCode?.trim().isNotEmpty ?? false)) {
      options.add(_MapScopeOption.postal());
    }

    final commandCenters = await ref.watch(
      staffManagedCommandCentersProvider.future,
    );
    options.addAll(commandCenters.map(_MapScopeOption.commandCenter));
    return options;
  }

  return options;
});

class MapsPage extends ConsumerStatefulWidget {
  const MapsPage({super.key});

  @override
  ConsumerState<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends ConsumerState<MapsPage> {
  User? currentUser;
  String? _selectedMapScopeId;
  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() async {
    final user = await ref.read(currentUserProvider.future);
    if (!mounted) return;
    setState(() {
      currentUser = user;
    });
  }

  Future<void> _reloadMapData() async {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Refreshing map data...'),
        duration: const Duration(seconds: 1),
        backgroundColor: theme.colorScheme.primary,
      ),
    );

    try {
      final freshUser = await ref.read(currentUserProvider.future);

      if (!mounted) return;
      setState(() {
        currentUser = freshUser;
      });

      await _refreshVisibleMapData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to refresh data. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  _MapScopeOption? _resolveSelectedScope(List<_MapScopeOption> options) {
    if (options.isEmpty) {
      return null;
    }

    final selectedId = _selectedMapScopeId;
    if (selectedId != null) {
      for (final option in options) {
        if (option.id == selectedId) {
          return option;
        }
      }
    }

    return options.first;
  }

  Future<void> _loadScopeOption(
    _MapScopeOption option, {
    bool includeHomeMarker = false,
  }) async {
    final controller = ref.read(mapControllerProvider.notifier);
    final user = await ref.read(currentUserProvider.future);

    List<EvacuationCenter> centers;
    switch (option.type) {
      case _MapScopeType.commandCenter:
        final commandCenterId = option.commandCenterId;
        if (commandCenterId == null || commandCenterId.isEmpty) {
          centers = [];
        } else {
          centers = await ref.read(
            centersByCommandCenterProvider(commandCenterId).future,
          );
        }
        break;
      case _MapScopeType.postal:
        centers = await ref.read(currentUserPostalCentersProvider.future);
        break;
    }

    if (!mounted) return;

    await controller.clearAllMarkers();
    controller.cacheCenters(centers);
    await controller.renderAnnotationsForMap(
      user: user,
      centers: centers,
      showHomeMarker: includeHomeMarker,
    );
  }

  Future<void> _refreshVisibleMapData() async {
    final user = await ref.read(currentUserProvider.future);
    if (!mounted || user == null) return;

    if (user.role == UserPermission.admin ||
        user.role == UserPermission.staff) {
      final options = await ref.read(mapScopeOptionsProvider.future);
      if (options.isEmpty) {
        final controller = ref.read(mapControllerProvider.notifier);
        await controller.clearAllMarkers();
        return;
      }

      final selectedOption = _resolveSelectedScope(options);
      if (selectedOption == null) return;
      await _loadScopeOption(
        selectedOption,
        includeHomeMarker: selectedOption.type == _MapScopeType.postal,
      );
      return;
    }

    final controller = ref.read(mapControllerProvider.notifier);
    final centers = await ref.read(relatedCentersProvider.future);
    await controller.clearAllMarkers();
    controller.cacheCenters(centers);
    await controller.renderAnnotationsForMap(user: user, centers: centers);
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    if (!mounted) return;

    final controller = ref.read(mapControllerProvider.notifier);
    await controller.configureMap(mapboxMap);
    final user = await ref.read(currentUserProvider.future);
    if (!mounted) return;
    setState(() {
      currentUser = user;
    });

    ref
        .read(mapControllerProvider)
        .pointAnnotationManager
        ?.tapEvents(
          onTap: (annotation) {
            final centerId = _extractCenterId(annotation.customData);
            if (centerId != null) {
              final center = controller.findCenterById(centerId);
              if (center != null) {
                _handleMarkerTap(center);
              }
            }
            return true;
          },
        );
    await _refreshVisibleMapData();
  }

  String? _extractCenterId(Object? rawCustomData) {
    if (rawCustomData is Map) {
      final dynamic id = rawCustomData['id'];
      return id?.toString();
    }

    if (rawCustomData is String && rawCustomData.isNotEmpty) {
      try {
        final decoded = rawCustomData.startsWith('{')
            ? Map<String, dynamic>.from(
                Map<Object?, Object?>.from(jsonDecode(rawCustomData)),
              )
            : null;
        return decoded?['id']?.toString();
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  Future<void> _onMapLongPressed(MapContentGestureContext mapContext) async {
    Map<String, dynamic> data; // location data dictionary from Geolocator
    final theme = Theme.of(context);
    final isOnline = await ref.watch(isOnlineProvider.future);

    try {
      currentUser = await ref.read(currentUserProvider.future);
      data = await ref
          .read(mapControllerProvider.notifier)
          .getAddressFromCoords(
            double.parse(mapContext.point.coordinates.lat.toString()),
            double.parse(mapContext.point.coordinates.lng.toString()),
          );
    } catch (e, stackTrace) {
      debugPrint('Failed to load current user for map long press: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to determine user access.')),
        );
      }
      rethrow;
    }
    if (!mounted) return;

    final point = mapContext.point;

    switch (currentUser?.role) {
      case UserPermission.admin:
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Choose an action'),
              content: const Text(
                'What would you like to add at this location?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    if (!isOnline) {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => _showOfflineMessage(theme),
                      );
                      return;
                    }

                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: AddEvacSheet(
                            point: point,
                            fullAddress: data['properties']['full_address'],
                            postalCode:
                                data['properties']['context']['postcode']['name'],
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('Add evacuation center'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    if (!isOnline) {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => _showOfflineMessage(theme),
                      );
                      return;
                    }

                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: AddUserLocation(
                            point: point,
                            fullAddress: data['properties']['full_address'],
                            postalCode:
                                data['properties']['context']['postcode']['name'],
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('Add home location'),
                ),
              ],
            );
          },
        );
        return;
      case UserPermission.staff:
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: isOnline
                  ? AddUserLocation(
                      point: point,
                      fullAddress: data['properties']['full_address'],
                      postalCode:
                          data['properties']['context']['postcode']['name'],
                    )
                  : _showOfflineMessage(theme),
            );
          },
        );
        return;
      case UserPermission.user:
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: isOnline
                  ? AddUserLocation(
                      point: point,
                      fullAddress: data['properties']['full_address'],
                      postalCode:
                          data['properties']['context']['postcode']['name'],
                    )
                  : _showOfflineMessage(theme),
            );
          },
        );
        return;
      case null:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only admins can add evacuation centers'),
          ),
        );
        return;
    }
  }

  void _handleMarkerTap(EvacuationCenter evacuationCenter) {
    debugPrint('Marker tapped for center ${evacuationCenter.id}');
    final center = ref
        .read(mapControllerProvider.notifier)
        .findCenterById(evacuationCenter.id);

    if (center != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => EvacInfoBotsheet(center: center),
      );
    } else {
      debugPrint('Tapped marker did not resolve to a cached center.');
    }
  }

  Widget _showOfflineMessage(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "You're offline right now",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We need a quick connection for this action. Please try again once your signal returns.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Got it",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapControllerProvider);
    final mapProvider = ref.watch(mapControllerProvider.notifier);
    final theme = Theme.of(context);
    final mapScopeOptionsAsync = ref.watch(mapScopeOptionsProvider);

    AppBar appBar = AppBar(
      backgroundColor: Colors.white.withAlpha(95),
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.map_outlined,
            color: theme.colorScheme.primary,
            size: 22,
          ),
        ),
      ),
      titleSpacing: 8,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentUser?.postalCode != null
                ? "Postal: ${currentUser!.postalCode}"
                : "Loading Location...",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            currentUser?.fullAddress ?? "Fetching coordinates...",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: Icon(Icons.help_outline_rounded, color: Colors.grey.shade700),
            style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const MapTutorialDialog(),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: Icon(Icons.refresh_outlined, color: Colors.grey.shade700),
            style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
            onPressed: () => _reloadMapData(),
          ),
        ),
      ],
    );

    if (mapScopeOptionsAsync.hasValue &&
        mapScopeOptionsAsync.value!.isNotEmpty) {
      final options = mapScopeOptionsAsync.value!;
      final selectedOption = _resolveSelectedScope(options);
      final activeOptionId = selectedOption?.id;

      final effectiveSelectedId = _selectedMapScopeId ?? activeOptionId;
      final dropdownOptions = options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.id,
              child: Text(option.label),
            ),
          )
          .toList();

      appBar = AppBar(
        backgroundColor: Colors.white.withAlpha(95),
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(20),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.map_outlined,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
        ),
        titleSpacing: 8,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentUser?.postalCode != null
                  ? "Postal: ${currentUser!.postalCode}"
                  : "Loading Location...",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              currentUser?.fullAddress ?? "Fetching coordinates...",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: DropdownButtonFormField<String>(
              value: effectiveSelectedId,
              items: dropdownOptions,
              onChanged: (value) async {
                if (value == null) return;
                final option = options.firstWhere((item) => item.id == value);
                setState(() {
                  _selectedMapScopeId = value;
                });
                await _loadScopeOption(
                  option,
                  includeHomeMarker: option.type == _MapScopeType.postal,
                );
              },
              decoration: InputDecoration(
                labelText: 'Map view',
                prefixIcon: const Icon(Icons.filter_list_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                Icons.help_outline_rounded,
                color: Colors.grey.shade700,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const MapTutorialDialog(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.refresh_outlined, color: Colors.grey.shade700),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
              ),
              onPressed: () => _reloadMapData(),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: appBar,
      extendBodyBehindAppBar: true,
      body: MapWidget(
        key: const ValueKey("mapWidget"),
        onMapCreated: _onMapCreated,
        onLongTapListener: (context) => _onMapLongPressed(context),
        cameraOptions: CameraOptions(
          center: Point(
            coordinates: Position(
              currentUser?.longitude ?? 121.7740,
              currentUser?.latitude ?? 12.8797,
            ),
          ),
          zoom: (currentUser?.fullAddress != null) ? 16.0 : 5.0,
          bearing: 0,
          pitch: 0,
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: mapProvider.focusOnUser,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: mapState.isBusy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.my_location_rounded),
      ),
    );
  }
}
