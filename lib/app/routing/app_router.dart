import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/coach/presentation/coach_result_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/intelligence/presentation/discipline_meter_screen.dart';
import '../../features/intelligence/presentation/risk_meter_screen.dart';
import '../../features/learning/presentation/missions_screen.dart';
import '../../features/learning/presentation/news_detective_screen.dart';
import '../../features/market/presentation/asset_detail_screen.dart';
import '../../features/market/presentation/markets_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/portfolio/presentation/portfolio_screen.dart';
import '../../features/portfolio/presentation/trade_history_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/subscription/presentation/paywall_screen.dart';
import '../../features/trading/presentation/trade_screen.dart';

class RouterListenable extends ChangeNotifier {
  final Ref _ref;

  RouterListenable(this._ref) {
    _ref.listen<AuthState>(authStateProvider, (_, __) => notifyListeners());
    _ref.listen<Map<String, bool>>(
        onboardingNotifierProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);

    // 1. While session restoration is in progress on startup, suppress redirect to prevent screen flicker.
    if (authState.isRestoring) {
      return null;
    }

    final loc = state.matchedLocation;
    final isAuthRoute = loc == '/login' || loc == '/register';
    final isOnboardingRoute = loc == '/onboarding';

    // 2. Unauthenticated state
    if (!authState.isAuthenticated && !authState.isAuthenticating) {
      if (isAuthRoute) return null;
      return '/login';
    }

    // 3. Authenticated state
    if (authState.isAuthenticated) {
      final user = authState.user;
      final onboardingNotifier = _ref.read(onboardingNotifierProvider.notifier);
      final onboardingDone = onboardingNotifier.isCompleted(user?.id);

      if (!onboardingDone) {
        if (isOnboardingRoute) return null;
        return '/onboarding';
      } else {
        if (isAuthRoute || isOnboardingRoute) {
          return '/home';
        }
        return null;
      }
    }

    return null;
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboardKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _shellNavigatorMarketsKey = GlobalKey<NavigatorState>(debugLabel: 'markets');
final _shellNavigatorTradeKey = GlobalKey<NavigatorState>(debugLabel: 'trade');
final _shellNavigatorPortfolioKey = GlobalKey<NavigatorState>(debugLabel: 'portfolio');

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = RouterListenable(ref);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: listenable,
    redirect: listenable.redirect,
    routes: _appRoutes,
  );
});

final List<RouteBase> _appRoutes = [
  GoRoute(
    path: '/onboarding',
    builder: (context, state) => const OnboardingScreen(),
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
      // NOTE: AppShell uses the child navigation shell.
      return AppShell(child: navigationShell);
    },
    branches: [
      StatefulShellBranch(
        navigatorKey: _shellNavigatorDashboardKey,
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
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
            // Defaulting to trade entry screen. 
            builder: (context, state) => const Scaffold(body: Center(child: Text('Trade Entry'))),
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
];

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: _appRoutes,
);
