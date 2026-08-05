import 'package:cryptoedu/app/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:cryptoedu/features/home/presentation/app_shell.dart';
import 'package:cryptoedu/features/trading/presentation/trade_entry_screen.dart';
import 'package:cryptoedu/shared/widgets/crypto_loading_indicator.dart';
import 'package:cryptoedu/shared/widgets/primary_button.dart';
import 'package:cryptoedu/shared/widgets/trade_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );
  }

  testWidgets('TradeCard runs its tap action', (tester) async {
    var wasTapped = false;

    await tester.pumpWidget(
      buildTestApp(
        TradeCard(
          semanticLabel: 'Portfolio equity',
          onTap: () => wasTapped = true,
          child: const Text('₹100,000 virtual equity'),
        ),
      ),
    );

    await tester.tap(find.text('₹100,000 virtual equity'));

    expect(wasTapped, isTrue);
  });

  testWidgets('PrimaryButton exposes loading and disabled states',
      (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        const PrimaryButton(
          label: 'Place virtual order',
          isLoading: true,
          onPressed: null,
        ),
      ),
    );

    // PrimaryButton renders its custom Bitcoin-GIF loader when loading.
    expect(find.byType(CryptoLoadingIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
  });

  testWidgets('AppShell switches between its four primary destinations',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/0',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/0', builder: (_, __) => const Center(child: Text('Dashboard content')))]),
            StatefulShellBranch(routes: [GoRoute(path: '/1', builder: (_, __) => const Center(child: Text('Markets content')))]),
            StatefulShellBranch(routes: [GoRoute(path: '/2', builder: (_, __) => const Center(child: Text('Trade content')))]),
            StatefulShellBranch(routes: [GoRoute(path: '/3', builder: (_, __) => const Center(child: Text('Portfolio content')))]),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard content'), findsOneWidget);
    expect(find.text('Markets content'), findsNothing);

    await tester.tap(find.text('Markets'));
    await tester.pumpAndSettle();

    expect(find.text('Markets content'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Trade'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
  });

  testWidgets('TradeEntryScreen labels every order as simulated',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: buildTestApp(const TradeEntryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Practice with virtual cash'), findsOneWidget);
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.textContaining('No cryptocurrency is bought or sold.'),
        findsOneWidget);
  });
}
