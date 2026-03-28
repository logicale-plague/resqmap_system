import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state/index.dart';

/// A generic widget builder for AsyncValue that handles data, loading, and error states.
///
/// This widget reduces boilerplate by centralizing the common .when() pattern
/// used across screens. It automatically handles:
/// - Loading state: Shows AppLoadingState
/// - Error state: Shows AppErrorState with optional prefix
/// - Data state: Calls the builder function with the data
class AsyncDataBuilder<T> extends StatelessWidget {
  final AsyncValue<T> asyncValue;
  final Widget Function(T data) builder;
  final String? errorPrefix;
  final bool showErrorPrefix;

  const AsyncDataBuilder({
    super.key,
    required this.asyncValue,
    required this.builder,
    this.errorPrefix,
    this.showErrorPrefix = true,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (data) => builder(data),
      loading: () => const AppLoadingState(),
      error: (error, stackTrace) => AppErrorState(
        error: error,
        stackTrace: stackTrace,
        prefix: showErrorPrefix ? (errorPrefix ?? 'Error') : '',
      ),
    );
  }
}
