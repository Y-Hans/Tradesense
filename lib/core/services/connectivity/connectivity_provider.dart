import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';
import 'connectivity_status.dart';

/// Provider for the [ConnectivityService] instance.
/// Allows overriding for testing or alternate implementations.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityServiceImpl();
  ref.onDispose(() => service.dispose());
  return service;
});

/// StateNotifier that manages application network connectivity state.
class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  final ConnectivityService _service;
  StreamSubscription<ConnectivityStatus>? _subscription;

  ConnectivityNotifier(
    this._service, {
    ConnectivityStatus initialStatus = ConnectivityStatus.unknown,
  }) : super(initialStatus) {
    _init();
  }

  void _init() {
    _subscription = _service.onStatusChanged.listen((status) {
      if (mounted) {
        state = status;
      }
    });

    _service.status.then((currentStatus) {
      if (mounted) {
        state = currentStatus;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Main connectivity provider exposing [ConnectivityStatus] directly.
/// Usage: `final status = ref.watch(connectivityProvider);`
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return ConnectivityNotifier(service);
});
