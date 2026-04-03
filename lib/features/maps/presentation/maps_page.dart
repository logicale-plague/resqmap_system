import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/authentication/domain/user.dart';
import 'package:kalig_onan_evac_system/features/authentication/presentation/providers/user_provider.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/providers/map_provider.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/widgets/add_evac_sheet.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/index.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/widgets/add_user_location.dart';
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

  void _onMapCreated(MapboxMap mapboxMap) async {
    final controller = ref.read(mapControllerProvider.notifier);
    await controller.configureMap(mapboxMap);
    ref
        .read(mapControllerProvider)
        .pointAnnotationManager
        ?.tapEvents(
          onTap: (p0) {
            _handleMarkerTap(p0);
            return true;
          },
        );

    final centers = await ref.read(relatedCentersProvider.future);

    // // // Load/pinpoint user homelocation in map if available
    if (currentUser?.latitude != null && currentUser?.longitude != null) {
      await controller.addMarkerToMap(
        point: Point(
          coordinates: Position(
            num.parse(currentUser!.longitude.toString()),
            num.parse(currentUser!.latitude.toString()),
          ),
        ),
        label: "My Home",
      );

      // // // THIs will load all the centers that are in teh same postal as the user
      if (centers.isNotEmpty) {
        print('Adding ${centers.length} centers to map...');
        for (final center in centers) {
          await controller.addMarkerToMap(
            point: Point(
              coordinates: Position(center.longitude, center.latitude),
            ),
            label: center.name,
          );
        }
      }
    }
  }

  Future<void> _onMapLongPressed(MapContentGestureContext mapContext) async {
    Map<String, dynamic> data; // location data dictionary from Geolocator

    try {
      currentUser = await ref.read(currentUserProvider.future);
      // // // // DEBUG  DEBUG DEBUG // // // //
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
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: AddEvacSheet(
                point: point,
                fullAddress: data['properties']['full_address'],
                postalCode: data['properties']['context']['postcode']['name'],
              ),
            );
          },
        );
        return;
      case UserPermission.staff:
        await showModalBottomSheet(
          context: context,
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: const Text(
                "View only mode: Only admins can add evacuation centers.",
                style: TextStyle(fontSize: 16),
              ),
            );
          },
        );
        return;
      case UserPermission.user:
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: AddUserLocation(
                point: point,
                fullAddress: data['properties']['full_address'],
                postalCode: data['properties']['context']['postcode']['name'],
              ),
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

  void _handleMarkerTap(PointAnnotation annotation) {
    final center = ref
        .read(mapControllerProvider.notifier)
        .findCenterByAnnotationId(annotation.id);

    if (center != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                center.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Status: ${center.status.name}",
                style: TextStyle(
                  color: center.status == CenterStatus.operational
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              Text(
                "Capacity: ${center.availableSpaces} / ${center.totalCapacity}",
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                child: const Center(child: Text("Get Directions")),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapControllerProvider);
    final mapProvider = ref.watch(mapControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black26,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.cloud_done_outlined,
            color: Colors.greenAccent,
          ),
          onPressed: () {},
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Postal: ${currentUser?.postalCode ?? "N/A"}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              currentUser?.fullAddress ?? "N/A",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.question_mark), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
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
        backgroundColor: Colors.white,
        child: mapState.isBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location, color: Colors.blueAccent),
      ),
    );
  }
}
