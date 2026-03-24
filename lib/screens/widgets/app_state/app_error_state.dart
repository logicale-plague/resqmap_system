import 'package:flutter/material.dart';

class AppErrorState extends StatelessWidget {
  final Object error;
  final String prefix;

  const AppErrorState({super.key, required this.error, this.prefix = 'Error'});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$prefix: $error'));
  }
}