import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/indices/provider_index.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/providers/user_provider.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/providers/map_provider.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/widgets/add_evac_sheet.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/index.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/widgets/add_user_location.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/widgets/evac_info_botsheet.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/widgets/guide_user.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapsPage extends ConsumerStatefulWidget {
  const MapsPage({super.key});

  @override
  ConsumerState<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends ConsumerState<MapsPage> {
  User? currentUser;
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
    final controller = ref.read(mapControllerProvider.notifier);
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Refreshing map data...'),
        duration: const Duration(seconds: 1),
        backgroundColor: theme.colorScheme.primary,
      ),
    );

    try {
      final freshUser = await controller.refreshMapData();

      if (!mounted) return;
      setState(() {
        currentUser = freshUser;
      });
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

  void _onMapCreated(MapboxMap mapboxMap) async {
    final centers = await ref.read(relatedCentersProvider.future);
    final user = await ref.read(currentUserProvider.future);
    if (!mounted) return;
    setState(() {
      currentUser = user;
    });

    final controller = ref.read(mapControllerProvider.notifier);
    await controller.configureMap(mapboxMap);
    controller.cacheCenters(centers);
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
    await controller.renderAnnotationsForMap(user: user, centers: centers);
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
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return isOnline
                ? Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: AddEvacSheet(
                      point: point,
                      fullAddress: data['properties']['full_address'],
                      postalCode:
                          data['properties']['context']['postcode']['name'],
                    ),
                  )
                : _showOfflineMessage(theme);
          },
        );
        return;
      case UserPermission.staff:
        await showModalBottomSheet(
          context: context,
          builder: (context) {
            return isOnline
                ? Container(
                    padding: const EdgeInsets.all(24),
                    child: const Text(
                      "View only mode: Only admins can add evacuation centers.",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : _showOfflineMessage(theme);
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

    return Scaffold(
      appBar: AppBar(
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
      ),
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
