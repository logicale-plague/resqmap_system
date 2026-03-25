import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/features/centers/presentation/providers/evacuation_center_providers.dart';
import 'package:kalig_onan_evac_system/features/sync/presentation/providers/sync_provider.dart';
import 'package:kalig_onan_evac_system/core/utils/id_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:kalig_onan_evac_system/features/centers/data/evacuation_center.dart';

class MapState {
  final MapboxMap? mapboxMap;
  final PointAnnotationManager? pointAnnotationManager;
  final Map<String, EvacuationCenter> evacDataMap;
  final bool isBusy;
  // Annotation IDs whose Supabase push failed and are pending retry.
  final Set<String> pendingRetryIds;

  MapState({
    this.mapboxMap,
    this.pointAnnotationManager,
    this.evacDataMap = const {},
    this.isBusy = false,
    this.pendingRetryIds = const {},
  });

  MapState copyWith({
    MapboxMap? mapboxMap,
    PointAnnotationManager? pointAnnotationManager,
    Map<String, EvacuationCenter>? evacDataMap,
    bool? isBusy,
    Set<String>? pendingRetryIds,
  }) {
    return MapState(
      mapboxMap: mapboxMap ?? this.mapboxMap,
      pointAnnotationManager:
          pointAnnotationManager ?? this.pointAnnotationManager,
      evacDataMap: evacDataMap ?? this.evacDataMap,
      isBusy: isBusy ?? this.isBusy,
      pendingRetryIds: pendingRetryIds ?? this.pendingRetryIds,
    );
  }
}

class MapController extends Notifier<MapState> {
  bool _isAddingMarker = false;

  @override
  MapState build() {
    return MapState();
  }

  void setMap(MapboxMap mapboxMap) {
    state = state.copyWith(mapboxMap: mapboxMap);
  }

  void setPointAnnotationManager(PointAnnotationManager manager) {
    state = state.copyWith(pointAnnotationManager: manager);
  }

  Future<void> configureMap(MapboxMap mapboxMap) async {
    setMap(mapboxMap);

    mapboxMap.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );

    mapboxMap.scaleBar.updateSettings(
      ScaleBarSettings(
        position: OrnamentPosition.BOTTOM_LEFT,
        marginBottom: 30,
      ),
    );

    mapboxMap.compass.updateSettings(
      CompassSettings(position: OrnamentPosition.TOP_RIGHT, marginTop: 100),
    );

    mapboxMap.setBounds(
      CameraBoundsOptions(
        bounds: CoordinateBounds(
          southwest: Point(coordinates: Position(116.0, 4.0)),
          northeast: Point(coordinates: Position(127.0, 21.0)),
          infiniteBounds: false,
        ),
        maxZoom: 20.0,
        minZoom: 5.0,
      ),
    );

    final manager = await mapboxMap.annotations.createPointAnnotationManager();
    setPointAnnotationManager(manager);
  }

  Future<void> focusOnUser() async {
    try {
      state = state.copyWith(isBusy: true);
      loc.Location location = loc.Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) return;
      }
      if (permission == geo.LocationPermission.deniedForever) {
        await geo.Geolocator.openAppSettings();
        return;
      }

      geo.Position position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );

      state.mapboxMap?.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 16.0,
          bearing: 0,
          pitch: 0,
        ),
        MapAnimationOptions(duration: 2000),
      );
    } catch (_) {
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> addMarkerToMap({
    required Point point,
    required String centerName,
  }) async {
    // Check online status before allowing creation
    final syncService = ref.read(syncServiceProvider);
    if (!syncService.isOnline) {
      throw Exception('Cannot create center: No internet connection');
    }

    final manager = state.pointAnnotationManager;
    if (manager == null) return;

    // Guard against double-submit: return early if already in progress
    if (_isAddingMarker) return;
    _isAddingMarker = true;

    try {
      final currentCommandCenterId = await ref.read(
        currentCommandCenterIdProvider.future,
      );

      final ByteData bytes = await rootBundle.load(
        'assets/map_icons/shelter-icon.png',
      );
      final Uint8List imageData = bytes.buffer.asUint8List();

      final annotation = await manager.create(
        PointAnnotationOptions(
          geometry: point,
          image: imageData,
          iconSize: 0.08,
          textField: centerName,
          textColor: 0xFF07A439,
          textOffset: [0.0, 1.6],
          textSize: 14.0,
          textHaloColor: 0xFFFFFFFF,
          textHaloWidth: 2.0,
        ),
      );

      final newCenter = EvacuationCenter(
        id: IdService.newId(),
        name: centerName,
        commandCenterId: currentCommandCenterId,
        latitude: point.coordinates.lat.toDouble(),
        longitude: point.coordinates.lng.toDouble(),
        totalCapacity: 0,
        currentOccupancy: 0,
        status: CenterStatus.operational,
        lastUpdated: DateTime.now(),
        synced: false,
      );

      // Store center in local state for UI display
      state = state.copyWith(
        evacDataMap: {...state.evacDataMap, annotation.id: newCenter},
      );

      // Push directly to Supabase (not to local database)
      try {
        await syncService.pushCenterToSupabase(newCenter);

        // Push succeeded: mark center as synced and clear any pending-retry flag
        final syncedCenter = newCenter.copyWith(synced: true);
        state = state.copyWith(
          evacDataMap: {...state.evacDataMap, annotation.id: syncedCenter},
          pendingRetryIds: state.pendingRetryIds.difference({annotation.id}),
        );

        // Invalidate the provider to refresh centers list from Supabase
        ref.invalidate(allCentersProvider);
      } catch (e) {
        // Push failed: keep the annotation and center in state so reconciliation
        // can retry; do NOT delete the annotation or remove from evacDataMap,
        // as that would orphan a potential remote row and discard local work.
        state = state.copyWith(
          pendingRetryIds: {...state.pendingRetryIds, annotation.id},
        );
        rethrow;
      }
    } finally {
      _isAddingMarker = false;
    }
  }

  EvacuationCenter? findCenterByAnnotationId(String annotationId) {
    return state.evacDataMap[annotationId];
  }
}

final mapControllerProvider = NotifierProvider<MapController, MapState>(() {
  return MapController();
});
