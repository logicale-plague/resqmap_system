import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  // Yield initial connectivity status
  final initialResult = await connectivity.checkConnectivity();
  yield initialResult != ConnectivityResult.none;

  // Listen to connectivity changes
  await for (final result in connectivity.onConnectivityChanged) {
    yield result != ConnectivityResult.none;
  }
});

final isOnlineProvider = FutureProvider<bool>((ref) async {
  final connectivity = Connectivity();
  final result = await connectivity.checkConnectivity();
  return result != ConnectivityResult.none;
});
