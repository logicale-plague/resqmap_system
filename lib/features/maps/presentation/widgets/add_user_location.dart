import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class AddUserLocation extends ConsumerStatefulWidget {
  final Point point;
  const AddUserLocation({super.key, required this.point});

  @override
  ConsumerState<AddUserLocation> createState() => _AddUserLocationState();
}

class _AddUserLocationState extends ConsumerState<AddUserLocation> {
  final TextEditingController _userLocationController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _latController.text = widget.point.coordinates.lat.toStringAsFixed(6);
    _lngController.text = widget.point.coordinates.lng.toStringAsFixed(6);
  }

  @override
  void dispose() {
    _userLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
