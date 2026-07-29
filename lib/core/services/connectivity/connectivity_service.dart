import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'connectivity_status.dart';

/// Abstract contract for monitoring device connectivity.
///
/// Features consume this contract without needing to depend on specific
/// network connectivity packages.
abstract class ConnectivityService {
  /// Asynchronously fetches the current connectivity status.
  Future<ConnectivityStatus> get status;

  /// Stream emitting connectivity status changes in real-time.
  Stream<ConnectivityStatus> get onStatusChanged;

  /// Disposes any stream subscriptions or controllers.
  void dispose();
}

/// Default implementation of [ConnectivityService] wrapping [Connectivity] from `connectivity_plus`.
class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityServiceImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<ConnectivityStatus> get status async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _mapResultsToStatus(results);
    } catch (_) {
      return ConnectivityStatus.offline;
    }
  }

  @override
  Stream<ConnectivityStatus> get onStatusChanged {
    return _connectivity.onConnectivityChanged.map(_mapResultsToStatus);
  }

  /// Maps a list of [ConnectivityResult] to [ConnectivityStatus].
  ///
  /// Online when any connection type other than [ConnectivityResult.none] is active.
  static ConnectivityStatus _mapResultsToStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.every((result) => result == ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }
    return ConnectivityStatus.online;
  }

  @override
  void dispose() {
    // Clean up if needed
  }
}
