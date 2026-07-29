import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cryptoedu/app/app.dart';
import 'package:cryptoedu/app/shell/app_shell.dart';
import 'package:cryptoedu/app/shell/global_status_region.dart';
import 'package:cryptoedu/core/services/connectivity/connectivity_provider.dart';
import 'package:cryptoedu/core/services/connectivity/connectivity_service.dart';
import 'package:cryptoedu/core/services/connectivity/connectivity_status.dart';
import 'package:cryptoedu/shared/widgets/connectivity_banner.dart';
import 'package:cryptoedu/shared/widgets/status_banner.dart';

class _FakeConnectivityService implements ConnectivityService {
  ConnectivityStatus _status;
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  _FakeConnectivityService({
    ConnectivityStatus initialStatus = ConnectivityStatus.online,
  }) : _status = initialStatus;

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
    _controller.close();
  }
}

void main() {
  group('ConnectivityBanner Widget Tests', () {
    late _FakeConnectivityService fakeService;

    setUp(() {
      fakeService = _FakeConnectivityService(
        initialStatus: ConnectivityStatus.unknown,
      );
    });

    tearDown(() {
      fakeService.dispose();
    });

    testWidgets('unknown status -> banner is hidden (0 height, no layout space)',
        (WidgetTester tester) async {
      fakeService = _FakeConnectivityService(
        initialStatus: ConnectivityStatus.unknown,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ConnectivityBanner(),
                  Text('Content Area'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text("You're offline"), findsNothing);
      expect(find.text("Some live features are temporarily unavailable."), findsNothing);

      // Verify StatusBanner is rendered with zero size / shrink
      final statusBannerFinder = find.byType(StatusBanner);
      expect(statusBannerFinder, findsOneWidget);
      final size = tester.getSize(statusBannerFinder);
      expect(size.height, equals(0.0));
    });

    testWidgets('online status -> banner remains hidden',
        (WidgetTester tester) async {
      fakeService = _FakeConnectivityService(
        initialStatus: ConnectivityStatus.online,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ConnectivityBanner(),
                  Text('Content Area'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("You're offline"), findsNothing);
      final statusBannerFinder = find.byType(StatusBanner);
      expect(tester.getSize(statusBannerFinder).height, equals(0.0));
    });

    testWidgets('offline status -> persistent banner appears with title, subtitle, and icon',
        (WidgetTester tester) async {
      fakeService = _FakeConnectivityService(
        initialStatus: ConnectivityStatus.offline,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ConnectivityBanner(),
                  Text('Content Area'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("You're offline"), findsOneWidget);
      expect(find.text("Some live features are temporarily unavailable."), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      final statusBannerFinder = find.byType(StatusBanner);
      expect(tester.getSize(statusBannerFinder).height, greaterThan(0.0));
    });

    testWidgets('state transitions: unknown -> online -> offline -> online',
        (WidgetTester tester) async {
      fakeService = _FakeConnectivityService(
        initialStatus: ConnectivityStatus.unknown,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ConnectivityBanner(),
                  Text('Content Area'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text("You're offline"), findsNothing);

      // Transition to online
      fakeService.setStatus(ConnectivityStatus.online);
      await tester.pumpAndSettle();
      expect(find.text("You're offline"), findsNothing);

      // Transition to offline
      fakeService.setStatus(ConnectivityStatus.offline);
      await tester.pumpAndSettle();
      expect(find.text("You're offline"), findsOneWidget);
      expect(find.text("Some live features are temporarily unavailable."), findsOneWidget);

      // Transition back to online
      fakeService.setStatus(ConnectivityStatus.online);
      await tester.pumpAndSettle();
      expect(find.text("You're offline"), findsNothing);
    });

    testWidgets('global integration: AppShell & GlobalStatusRegion display banner globally',
        (WidgetTester tester) async {
      fakeService = _FakeConnectivityService(
        initialStatus: ConnectivityStatus.offline,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityServiceProvider.overrideWithValue(fakeService),
          ],
          child: const CryptoEduApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(GlobalStatusRegion), findsOneWidget);
      expect(find.byType(ConnectivityBanner), findsOneWidget);
      expect(find.text("You're offline"), findsOneWidget);
    });

    testWidgets('GlobalStatusRegion preserves intended banner ordering in layout hierarchy',
        (WidgetTester tester) async {
      fakeService = _FakeConnectivityService(
        initialStatus: ConnectivityStatus.offline,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GlobalStatusRegion(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final statusRegionFinder = find.byType(GlobalStatusRegion);
      expect(statusRegionFinder, findsOneWidget);

      final Column columnWidget = tester.widget<Column>(
        find.descendant(
          of: statusRegionFinder,
          matching: find.byWidgetPredicate(
            (w) => w is Column && w.children.any((c) => c is ConnectivityBanner),
          ),
        ),
      );

      expect(columnWidget.children.first, isA<ConnectivityBanner>());
    });

    testWidgets('accessibility: banner exposes proper semantics and liveRegion',
        (WidgetTester tester) async {
      fakeService = _FakeConnectivityService(
        initialStatus: ConnectivityStatus.offline,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ConnectivityBanner(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.liveRegion == true &&
            widget.properties.label != null &&
            widget.properties.label!.contains("You're offline"),
      );

      expect(semanticsFinder, findsOneWidget);
    });
  });
}
