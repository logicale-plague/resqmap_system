import 'package:flutter/material.dart';

PreferredSizeWidget buildScreenAppBar({
  required String title,
  List<Widget>? actions,
}) {
  return AppBar(
    title: Text(title),
    backgroundColor: Colors.indigo,
    foregroundColor: Colors.white,
    actions: actions,
  );
}
