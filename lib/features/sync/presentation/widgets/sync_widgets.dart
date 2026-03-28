import 'package:flutter/material.dart';

Widget buildBulletPoint(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('\u2022 ', style: TextStyle(fontSize: 20)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );
}

Widget buildConnectionStatusBox(bool isOnline) {
  final color = isOnline ? Colors.green : Colors.red;
  final backgroundColor = isOnline ? Colors.green[50]! : Colors.red[50]!;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          isOnline ? Icons.cloud_done : Icons.cloud_off,
          size: 64,
          color: color,
        ),
        const SizedBox(height: 16),
        Text(
          isOnline ? 'CONNECTED' : 'OFFLINE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isOnline
              ? 'Connected to command center'
              : 'Working offline - data will sync when connected',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
