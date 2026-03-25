import 'package:flutter/material.dart';

class SelectableOptionCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget icon;
  final String label;
  final Color selectedColor;

  const SelectableOptionCard({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure that UI is as simple and battery-friendly as possible, especially for users in evacuation scenarios
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
