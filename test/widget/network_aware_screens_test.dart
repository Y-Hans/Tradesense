import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cryptoedu/core/services/connectivity/connectivity_provider.dart';
import 'package:cryptoedu/core/services/connectivity/connectivity_service.dart';
import 'package:cryptoedu/core/services/connectivity/connectivity_status.dart';
import 'package:cryptoedu/features/coach/presentation/coach_result_screen.dart';
import 'package:cryptoedu/features/market/presentation/asset_detail_screen.dart';
import 'package:cryptoedu/features/market/presentation/markets_screen.dart';
import 'package:cryptoedu/features/portfolio/presentation/portfolio_screen.dart';
import 'package:cryptoedu/shared/widgets/offline_state_widget.dart';

class _FakeConnectivityService implements ConnectivityService {
  ConnectivityStatus _status;
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  _FakeConnectivityService({
    ConnectivityStatus initialStatus = ConnectivityStatus.offline,
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
  group('Network-Aware Screens Widget Tests', () {
    late _FakeConnectivityService fakeService;

    setUp(() {
      fakeService = _FakeConnectivityService(
        initialStatus: ConnectivityStatus.offline,
      );
    });

    tearDown(() {
      fakeService.dispose();
    });

    testWidgets('CoachResultScreen displays network-aware message when offline',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: CoachResultScreen(tradeId: 'tr_mock_123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(OfflineStateWidget), findsOneWidget);
      expect(
        find.text('Connect to the internet to generate AI coaching.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'MarketsScreen displays network-aware offline widget when offline',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: MarketsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(OfflineStateWidget), findsOneWidget);
      expect(
        find.text('Live market prices are unavailable while offline.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'AssetDetailScreen displays compact network-aware banner when offline',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: AssetDetailScreen(symbol: 'BTC'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(OfflineStateWidget), findsOneWidget);
      expect(
        find.text(
          'Live market details and real-time prices are unavailable while offline.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'PortfolioScreen remains visible and shows cached data indicator when offline',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityServiceProvider.overrideWithValue(fakeService),
          ],
          child: const MaterialApp(
            home: PortfolioScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(OfflineStateWidget), findsOneWidget);
      expect(find.text('Showing cached data'), findsOneWidget);
      expect(find.text('Available Cash'), findsOneWidget);
      expect(find.text('Holdings Valuation'), findsOneWidget);
    });
  });
}
