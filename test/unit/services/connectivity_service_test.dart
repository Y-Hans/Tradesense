import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cryptoedu/core/services/connectivity/connectivity_provider.dart';
import 'package:cryptoedu/core/services/connectivity/connectivity_service.dart';
import 'package:cryptoedu/core/services/connectivity/connectivity_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake implementation of [Connectivity] from connectivity_plus for testing.
class _FakeConnectivity implements Connectivity {
  List<ConnectivityResult> currentResults;
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();

  _FakeConnectivity({required this.currentResults});

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return currentResults;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  void emit(List<ConnectivityResult> results) {
    currentResults = results;
    _controller.add(results);
  }

  void dispose() {
    _controller.close();
  }
}

/// Fake implementation of [ConnectivityService] for testing Riverpod providers.
class _FakeConnectivityService implements ConnectivityService {
  ConnectivityStatus _status;
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();
  bool isDisposed = false;

  _FakeConnectivityService(
      {ConnectivityStatus initialStatus = ConnectivityStatus.online})
      : _status = initialStatus;

  @override
  Future<ConnectivityStatus> get status async => _status;

  @override
  Stream<ConnectivityStatus> get onStatusChanged => _controller.stream;

  void setStatus(ConnectivityStatus newStatus) {
    _status = newStatus;
    _controller.add(newStatus);
  }

  @override
  void dispose() {
    isDisposed = true;
    _controller.close();
  }
}

void main() {
  group('ConnectivityStatus Domain Model', () {
    test('unknown status properties', () {
      const status = ConnectivityStatus.unknown;
      expect(status.isUnknown, isTrue);
      expect(status.isOnline, isFalse);
      expect(status.isOffline, isFalse);
    });

    test('online status properties', () {
      const status = ConnectivityStatus.online;
      expect(status.isOnline, isTrue);
      expect(status.isOffline, isFalse);
      expect(status.isUnknown, isFalse);
    });

    test('offline status properties', () {
      const status = ConnectivityStatus.offline;
      expect(status.isOnline, isFalse);
      expect(status.isOffline, isTrue);
      expect(status.isUnknown, isFalse);
    });
  });

  group('ConnectivityServiceImpl Unit Tests', () {
    late _FakeConnectivity fakeConnectivity;
    late ConnectivityServiceImpl service;

    setUp(() {
      fakeConnectivity = _FakeConnectivity(
        currentResults: [ConnectivityResult.wifi],
      );
      service = ConnectivityServiceImpl(connectivity: fakeConnectivity);
    });

    tearDown(() {
      fakeConnectivity.dispose();
      service.dispose();
    });

    test('returns online when WiFi connection is active', () async {
      fakeConnectivity.currentResults = [ConnectivityResult.wifi];
      final status = await service.status;
      expect(status, equals(ConnectivityStatus.online));
    });

    test('returns online when Cellular connection is active', () async {
      fakeConnectivity.currentResults = [ConnectivityResult.mobile];
      final status = await service.status;
      expect(status, equals(ConnectivityStatus.online));
    });

    test('returns offline when ConnectivityResult.none is active', () async {
      fakeConnectivity.currentResults = [ConnectivityResult.none];
      final status = await service.status;
      expect(status, equals(ConnectivityStatus.offline));
    });

    test('returns offline when results list is empty', () async {
      fakeConnectivity.currentResults = [];
      final status = await service.status;
      expect(status, equals(ConnectivityStatus.offline));
    });

    test('emits status changes over onStatusChanged stream', () async {
      final statuses = <ConnectivityStatus>[];
      final sub = service.onStatusChanged.listen(statuses.add);

      fakeConnectivity.emit([ConnectivityResult.none]);
      fakeConnectivity.emit([ConnectivityResult.wifi]);
      fakeConnectivity.emit([ConnectivityResult.mobile]);
      fakeConnectivity.emit([ConnectivityResult.none]);

      await pumpEventQueue();

      expect(
          statuses,
          equals([
            ConnectivityStatus.offline,
            ConnectivityStatus.online,
            ConnectivityStatus.online,
            ConnectivityStatus.offline,
          ]));

      await sub.cancel();
    });
  });

  group('ConnectivityNotifier & Riverpod Provider Unit Tests', () {
    late _FakeConnectivityService fakeService;

    setUp(() {
      fakeService = _FakeConnectivityService(
        initialStatus: ConnectivityStatus.online,
      );
    });

    tearDown(() {
      fakeService.dispose();
    });

    test(
        'ConnectivityNotifier defaults to unknown state before async check resolves',
        () {
      final notifier = ConnectivityNotifier(fakeService);
      expect(notifier.state, equals(ConnectivityStatus.unknown));
      notifier.dispose();
    });

    test(
        'ConnectivityNotifier initializes with service current status after async check',
        () async {
      fakeService = _FakeConnectivityService(
        initialStatus: ConnectivityStatus.offline,
      );
      final notifier = ConnectivityNotifier(fakeService);

      await pumpEventQueue();
      expect(notifier.state, equals(ConnectivityStatus.offline));

      notifier.dispose();
    });

    test(
        'ConnectivityNotifier updates state when service notifies onStatusChanged',
        () async {
      final notifier = ConnectivityNotifier(fakeService);
      await pumpEventQueue();
      expect(notifier.state, equals(ConnectivityStatus.online));

      fakeService.setStatus(ConnectivityStatus.offline);
      await pumpEventQueue();
      expect(notifier.state, equals(ConnectivityStatus.offline));

      fakeService.setStatus(ConnectivityStatus.online);
      await pumpEventQueue();
      expect(notifier.state, equals(ConnectivityStatus.online));

      notifier.dispose();
    });

    test(
        'connectivityProvider starts at unknown state synchronously then updates',
        () async {
      final container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      // Synchronously reads unknown before event queue processes _service.status
      expect(container.read(connectivityProvider),
          equals(ConnectivityStatus.unknown));

      await pumpEventQueue();
      expect(container.read(connectivityProvider),
          equals(ConnectivityStatus.online));

      // Emit offline transition
      fakeService.setStatus(ConnectivityStatus.offline);
      await pumpEventQueue();

      expect(container.read(connectivityProvider),
          equals(ConnectivityStatus.offline));
    });

    test('connectivityProvider notifies listeners on state change', () async {
      final container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final listenedStates = <ConnectivityStatus>[];
      container.listen<ConnectivityStatus>(
        connectivityProvider,
        (previous, next) => listenedStates.add(next),
        fireImmediately: false,
      );

      fakeService.setStatus(ConnectivityStatus.offline);
      await pumpEventQueue();

      fakeService.setStatus(ConnectivityStatus.online);
      await pumpEventQueue();

      expect(
          listenedStates,
          equals([
            ConnectivityStatus
                .online, // transition from initial unknown -> resolved online
            ConnectivityStatus.offline, // transition to offline
            ConnectivityStatus.online, // transition back to online
          ]));
    });
  });
}
