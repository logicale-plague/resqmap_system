import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalig_onan_evac_system/core/exceptions/offline_exception.dart';
import 'package:kalig_onan_evac_system/features/maps/presentation/providers/map_provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class AddUserLocation extends ConsumerStatefulWidget {
  final Point point;
  final String fullAddress;
  final String postalCode;

  const AddUserLocation({
    super.key,
    required this.fullAddress,
    required this.postalCode,
    required this.point,
  });

  @override
  ConsumerState<AddUserLocation> createState() => _AddUserLocationState();
}

class _AddUserLocationState extends ConsumerState<AddUserLocation> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _latController.text = widget.point.coordinates.lat.toStringAsFixed(6);
    _lngController.text = widget.point.coordinates.lng.toStringAsFixed(6);
    _addressController.text = widget.fullAddress;
    _postalCodeController.text = widget.postalCode;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _postalCodeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final address = _addressController.text.trim();
    final postalCode = _postalCodeController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your address.')),
      );
      return;
    }

    if (postalCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your postal code.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(mapControllerProvider.notifier)
          .addUserLocationToMap(
            point: widget.point,
            address: address,
            postalCode: postalCode,
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
          content: Text('Failed to set location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
            'Set User Location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${widget.point.coordinates.lat.toStringAsFixed(4)}, ${widget.point.coordinates.lng.toStringAsFixed(4)}',
          ),
          _buildTextField(controller: _addressController, label: 'Address'),
          _buildTextField(
            controller: _postalCodeController,
            label: 'Postal Code',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _latController,
                  label: 'Latitude',
                  enabled: false,
                ),
              ),
              Expanded(
                child: _buildTextField(
                  controller: _lngController,
                  label: 'Longitude',
                  enabled: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Set Location'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextField(
      enabled: enabled,
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: (_) {
        if (textInputAction == TextInputAction.done) {
          _submit();
        }
      },
    );
  }
}
