import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/startup/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/app_shell.dart';
import '../../features/market/presentation/asset_detail_screen.dart';
import '../../features/market/presentation/markets_screen.dart';
import '../../features/trading/presentation/trade_screen.dart';
import '../../features/trading/presentation/trade_entry_screen.dart';
import '../../features/portfolio/presentation/portfolio_screen.dart';
import '../../features/portfolio/presentation/trade_history_screen.dart';
import '../../features/intelligence/presentation/risk_meter_screen.dart';
import '../../features/intelligence/presentation/discipline_meter_screen.dart';
import '../../features/coach/presentation/coach_result_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/subscription/presentation/paywall_screen.dart';
import '../../features/learning/presentation/missions_screen.dart';
import '../../features/learning/presentation/news_detective_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboardKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _shellNavigatorMarketsKey = GlobalKey<NavigatorState>(debugLabel: 'markets');
final _shellNavigatorTradeKey = GlobalKey<NavigatorState>(debugLabel: 'trade');
final _shellNavigatorPortfolioKey = GlobalKey<NavigatorState>(debugLabel: 'portfolio');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => OnboardingScreen(
        onGetStarted: () => context.go('/home'),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorDashboardKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorMarketsKey,
          routes: [
            GoRoute(
              path: '/markets',
              builder: (context, state) => const MarketsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorTradeKey,
          routes: [
            GoRoute(
              path: '/trade',
              builder: (context, state) => const TradeEntryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorPortfolioKey,
          routes: [
            GoRoute(
              path: '/portfolio',
              builder: (context, state) => const PortfolioScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/asset/:symbol',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AssetDetailScreen(
        symbol: state.pathParameters['symbol'] ?? 'BTC',
      ),
    ),
    GoRoute(
      path: '/trade/:symbol',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => TradeScreen(
        symbol: state.pathParameters['symbol'] ?? 'BTC',
      ),
    ),
    GoRoute(
      path: '/trade-history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TradeHistoryScreen(),
    ),
    GoRoute(
      path: '/risk-meter',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RiskMeterScreen(),
    ),
    GoRoute(
      path: '/discipline-meter',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DisciplineMeterScreen(),
    ),
    GoRoute(
      path: '/coach-result/:tradeId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => CoachResultScreen(
        tradeId: state.pathParameters['tradeId'] ?? 'tr_mock_123',
      ),
    ),
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/paywall',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PaywallScreen(),
    ),
    GoRoute(
      path: '/missions',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MissionsScreen(),
    ),
    GoRoute(
      path: '/news-detective',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NewsDetectiveScreen(),
    ),
  ],
);
