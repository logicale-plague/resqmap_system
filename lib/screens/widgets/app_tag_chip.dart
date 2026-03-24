import 'package:flutter/material.dart';

class AppTagChip extends StatelessWidget {
  final String label;
  final Color? color;

  const AppTagChip({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final themeTextColor = Theme.of(context).textTheme.bodySmall?.color;
    final foregroundColor = color == null
        ? (themeTextColor ?? Colors.black)
        : (color!.computeLuminance() > 0.5 ? Colors.black : Colors.white);

    return Chip(
      label: Text(label),
      backgroundColor: color,
      labelStyle: TextStyle(fontSize: 12, color: foregroundColor),
    );
  }
}
