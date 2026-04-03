import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Performs a DNS lookup to verify actual internet reachability,
/// not just interface presence. Returns false for captive portals
/// or restricted networks that report a connection but have no access.
Future<bool> _verifyInternetAccess() async {
  try {
    final result = await InternetAddress.lookup(
      'google.com',
    ).timeout(const Duration(seconds: 5));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  final initialResult = await connectivity.checkConnectivity();
  yield initialResult != ConnectivityResult.none &&
      await _verifyInternetAccess();

  await for (final result in connectivity.onConnectivityChanged) {
    yield result != ConnectivityResult.none && await _verifyInternetAccess();
  }
});

final isOnlineProvider = FutureProvider<bool>((ref) async {
  // Reuse the authoritative connectivity stream so callers get updated
  // online/offline state after reconnection without forcing manual refresh.
  return ref.watch(connectivityProvider.future);
});
