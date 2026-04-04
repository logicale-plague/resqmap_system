import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kalig_onan_evac_system/core/exceptions/offline_exception.dart';
import 'package:kalig_onan_evac_system/core/providers/database_provider.dart';
import 'package:kalig_onan_evac_system/core/providers/supabase_provider.dart';
import 'package:kalig_onan_evac_system/features/admin/command_center/presentation/providers/command_center_providers.dart';
import 'package:kalig_onan_evac_system/features/authentication/data/user_persistence_extensions.dart';
// import 'package:kalig_onan_evac_system/core/providers/user_provider.dart' hide currentUserProvider;
import 'package:kalig_onan_evac_system/features/authentication/presentation/providers/user_provider.dart';
import 'package:kalig_onan_evac_system/features/centers/shared/index.dart';
import 'package:kalig_onan_evac_system/features/staff/sync/application/sync_service.dart';
import 'package:kalig_onan_evac_system/core/utils/id_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geolocator/geolocator.dart' as geo;

// diri lang ni danay kay tamadan ko mag ukay sang heirarchy sang evac center
final relatedCentersProvider = FutureProvider<List<EvacuationCenter>>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref.read(evacuationCenterRepositoryProvider).getAllViaPostal();
});

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
  PointAnnotation? _currentUserLocationAnnotation;

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

  // // // // FETCH SOMETHING VIA COORDINATES // // // //
  Future<Map<String, dynamic>> getAddressFromCoords(
    double lat,
    double lng,
  ) async {
    final accessToken = dotenv.env["MAPBOX_ACCESS_TOKEN"] ?? "";
    final url =
        'https://api.mapbox.com/search/geocode/v6/reverse?longitude=$lng&latitude=$lat&access_token=$accessToken&limit=1';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['features'][0];
      } else {
        return {"error": "Something went wrong"};
      }
    } catch (e) {
      return {"error": "Something went wrong"};
    }
  }

  Future<void> addMarkerToMap({
    required Point point,
    required String label,
    String? iconPath,
    String? annotationId,
  }) async {
    final manager = state.pointAnnotationManager;

    // Guard against double-submit: return early if already in progress
    if (_isAddingMarker) return;
    _isAddingMarker = true;

    if (manager != null) {
      try {
        final ByteData bytes = await rootBundle.load(
          iconPath ?? 'assets/map_icons/shelter-icon.png',
        );
        final Uint8List imageData = bytes.buffer.asUint8List();

        await manager.create(
          PointAnnotationOptions(
            geometry: point,
            image: imageData,
            iconSize: 0.07,
            textField: label,
            textColor: 0xFF1E88E5,
            textOffset: [0.0, 1.6],
            textSize: 13.0,
            textHaloColor: 0xFFFFFFFF,
            textHaloWidth: 2.0,
            customData: annotationId != null ? {'id': annotationId} : null,
          ),
        );
      } finally {
        _isAddingMarker = false;
      }
    }
  }

  void cacheCenters(List<EvacuationCenter> centers) {
    if (centers.isEmpty) return;
    final cachedCenters = {for (final center in centers) center.id: center};

    state = state.copyWith(
      evacDataMap: {...state.evacDataMap, ...cachedCenters},
    );
  }

  Future<void> addUserLocationToMap({
    required Point point,
    required String address,
    required String postalCode,
  }) async {
    // Check online status before allowing location update
    final syncService = ref.read(syncServiceProvider);
    if (!syncService.isOnline) {
      throw OfflineException('Cannot set location: No internet connection');
    }

    final manager = state.pointAnnotationManager;

    // Guard against double-submit: return early if already in progress
    if (_isAddingMarker) return;
    _isAddingMarker = true;

    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw StateError('No current user found.');
      }

      final updatedUser = currentUser.copyWith(
        latitude: point.coordinates.lat.toDouble(),
        longitude: point.coordinates.lng.toDouble(),
        fullAddress: address,
        postalCode: postalCode,
      );

      final dbService = ref.read(databaseServiceProvider);
      await dbService.replaceCurrentUser(updatedUser);

      final supabase = ref.read(supabaseProvider);
      try {
        await supabase
            .from('users')
            .update({
              'latitude': updatedUser.latitude,
              'longitude': updatedUser.longitude,
              'full_address': updatedUser.fullAddress,
              'postal_code': updatedUser.postalCode,
            })
            .eq('id', updatedUser.id);
      } catch (e) {
        rethrow;
      }
      ref.invalidate(currentUserProvider);

      if (manager != null) {
        if (_currentUserLocationAnnotation != null) {
          await manager.delete(_currentUserLocationAnnotation!);
          _currentUserLocationAnnotation = null;
        }

        final ByteData bytes = await rootBundle.load(
          'assets/map_icons/shelter-icon.png',
        );
        final Uint8List imageData = bytes.buffer.asUint8List();

        final annotation = await manager.create(
          PointAnnotationOptions(
            geometry: point,
            image: imageData,
            iconSize: 0.07,
            textField: 'My Location',
            textColor: 0xFF1E88E5,
            textOffset: [0.0, 1.6],
            textSize: 13.0,
            textHaloColor: 0xFFFFFFFF,
            textHaloWidth: 2.0,
          ),
        );
        _currentUserLocationAnnotation = annotation;
      }
    } finally {
      _isAddingMarker = false;
    }
  }

  Future<void> addEvacCenterToMap({
    required Point point,
    required String centerName,
    required String fullAddress,
    required String postalCode,
  }) async {
    // Check online status before allowing creation
    final syncService = ref.read(syncServiceProvider);
    if (!syncService.isOnline) {
      throw OfflineException('Cannot create center: No internet connection');
    }
    final manager = state.pointAnnotationManager;
    if (manager == null) return;

    // Guard against double-submit: return early if already in progress
    if (_isAddingMarker) return;
    _isAddingMarker = true;

    try {
      final currentCommandCenterId = ref.read(selectedCommandCenterIdProvider);
      if (currentCommandCenterId == null) {
        throw StateError(
          'No command center selected. Please select a command center before adding evacuation centers.',
        );
      }

      final newCenterId = IdService.newId();
      final newCenter = EvacuationCenter(
        id: newCenterId,
        name: centerName,
        commandCenterId: currentCommandCenterId,
        latitude: point.coordinates.lat.toDouble(),
        longitude: point.coordinates.lng.toDouble(),
        fullAddress: fullAddress,
        postalCode: postalCode,
        totalCapacity: 0,
        currentOccupancy: 0,
        status: CenterStatus.operational,
        lastUpdated: DateTime.now(),
        synced: false, // Default to false until sync succeeds
      );

      final ByteData bytes = await rootBundle.load(
        'assets/map_icons/shelter-icon.png',
      );
      final Uint8List imageData = bytes.buffer.asUint8List();

      await manager.create(
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
          customData: {'id': newCenterId},
        ),
      );

      // Store center in local state for UI display
      state = state.copyWith(
        evacDataMap: {...state.evacDataMap, newCenterId: newCenter},
      );

      try {
        final centerRepository = ref.read(evacuationCenterRepositoryProvider);
        // The repository should handle saving to local SQLite/Isar FIRST,
        // then attempt the Supabase push.
        await centerRepository.insert(newCenter);

        // Insert succeeded remotely: mark center as synced and clear pending-retry state.
        final syncedCenter = newCenter.copyWith(synced: true);
        state = state.copyWith(
          evacDataMap: {...state.evacDataMap, newCenterId: syncedCenter},
          pendingRetryIds: state.pendingRetryIds.difference({newCenterId}),
        );

        ref.invalidate(allCentersProvider);
      } catch (e) {
        // Insert failed remotely (e.g. offline).
        // Keep it in state, keep the annotation, but flag it for retry.
        state = state.copyWith(
          pendingRetryIds: {...state.pendingRetryIds, newCenterId},
        );
      }
    } finally {
      _isAddingMarker = false;
    }
  }

  EvacuationCenter? findCenterById(String id) {
    return state.evacDataMap[id];
  }
}

final mapControllerProvider = NotifierProvider<MapController, MapState>(() {
  return MapController();
});
