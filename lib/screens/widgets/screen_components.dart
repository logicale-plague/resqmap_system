import 'package:flutter/material.dart';

PreferredSizeWidget buildScreenAppBar({
  required String title,
  List<Widget>? actions,
}) {
  return AppBar(
    title: Text(title, style: const TextStyle(color: Colors.white)),
    backgroundColor: Colors.indigo,
    actions: actions,
  );
}

