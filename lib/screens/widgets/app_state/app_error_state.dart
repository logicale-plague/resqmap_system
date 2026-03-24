import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppErrorState extends StatefulWidget {
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
  State<AppErrorState> createState() => _AppErrorStateState();
}

class _AppErrorStateState extends State<AppErrorState> {
  void _logError() {
    if (!kDebugMode) return; // Skip logging when not in debug mode
    debugPrint('AppErrorState [${widget.prefix}]: ${widget.error}');
    if (widget.stackTrace != null) {
      debugPrintStack(stackTrace: widget.stackTrace);
    }
  }

  @override
  void initState() {
    super.initState();
    _logError();
  }

  @override
  void didUpdateWidget(covariant AppErrorState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.error != widget.error ||
        oldWidget.stackTrace != widget.stackTrace ||
        oldWidget.prefix != widget.prefix) {
      _logError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('${widget.prefix}: Something went wrong'));
  }
}
