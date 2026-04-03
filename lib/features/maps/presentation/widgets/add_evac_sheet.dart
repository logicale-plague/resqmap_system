import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/exceptions/offline_exception.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/providers/map_provider.dart';

class AddEvacSheet extends ConsumerStatefulWidget {
  final Point point;
  final String fullAddress;
  final String postalCode;
  const AddEvacSheet({
    super.key,
    required this.point,
    required this.postalCode,
    required this.fullAddress,
  });

  @override
  ConsumerState<AddEvacSheet> createState() => _AddEvacSheetState();
}

class _AddEvacSheetState extends ConsumerState<AddEvacSheet> {
  final TextEditingController _centerNameController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _latController.text = widget.point.coordinates.lat.toStringAsFixed(6);
    _lngController.text = widget.point.coordinates.lng.toStringAsFixed(6);
    _postalCodeController.text = widget.postalCode;
  }

  @override
  void dispose() {
    _centerNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final centerName = _centerNameController.text.trim();
    if (centerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a center name.')),
      );
      return;
    }

    try {
      await ref
          .read(mapControllerProvider.notifier)
          .addEvacCenterToMap(
            point: widget.point,
            centerName: centerName,
            fullAddress: widget.fullAddress,
            postalCode: widget.postalCode,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
    } on OfflineException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register center: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Setup Evacuation Center",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${widget.point.coordinates.lat.toStringAsFixed(4)}, ${widget.point.coordinates.lng.toStringAsFixed(4)}',
          ),
          _buildTextField(
            controller: _centerNameController,
            label: "Center Name",
          ),
          _buildTextField(
            controller: _postalCodeController,
            label: "Postal Code",
            enabled: false,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _latController,
                  label: "Latitude",
                  enabled: false,
                ),
              ),
              Expanded(
                child: _buildTextField(
                  controller: _lngController,
                  label: "Longitude",
                  enabled: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submit,
            child: const Text("Establish Center"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool? enabled,
  }) {
    return TextField(
      enabled: enabled ?? true,
      controller: controller,
      decoration: InputDecoration(labelText: label),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
    );
  }
}
