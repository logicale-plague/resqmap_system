import 'package:flutter/material.dart';

class AppTagChip extends StatelessWidget {
  final String label;
  final Color color;

  const AppTagChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: color,
      labelStyle: const TextStyle(fontSize: 12),
    );
  }
}