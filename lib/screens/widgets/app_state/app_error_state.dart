import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppErrorState extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final String prefix;

  const AppErrorState({
    super.key,
    required this.error,
    this.stackTrace,
    this.prefix = 'Error',
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('AppErrorState [$prefix]: $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }

    return Center(child: Text('$prefix: Something went wrong'));
  }
}