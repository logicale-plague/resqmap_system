import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/feature/provider/map_provider.dart';
import 'package:kalig_onan_evac_system/feature/widgets/add_evac_sheet.dart';
import 'package:kalig_onan_evac_system/models/evacuation_center.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapsPage extends ConsumerStatefulWidget {
  const MapsPage({super.key});

  @override
  ConsumerState<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends ConsumerState<MapsPage> {
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
  }

  // FEATURE FOR ADMIN
  void _onMapLongPressed(MapContentGestureContext mapContext) {
    final point = mapContext.point;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddEvacSheet(point: point),
        );
      },
    );
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Iloilo Crisis Map",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Scope: Brgy. San Jose",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.cloud_done_outlined,
              color: Colors.greenAccent,
            ),
            onPressed: () {},
          ),
          IconButton(icon: const Icon(Icons.layers_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: MapWidget(
        key: const ValueKey("mapWidget"),
        onMapCreated: _onMapCreated,
        onLongTapListener: (context) => _onMapLongPressed(context),
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(121.7740, 12.8797)),
          zoom: 5.0,
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
