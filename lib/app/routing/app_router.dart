import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/market/presentation/markets_screen.dart';
import '../../features/market/presentation/asset_detail_screen.dart';
import '../../features/trading/presentation/trade_screen.dart';
import '../../features/portfolio/presentation/portfolio_screen.dart';
import '../../features/portfolio/presentation/trade_history_screen.dart';
import '../../features/intelligence/presentation/risk_meter_screen.dart';
import '../../features/intelligence/presentation/discipline_meter_screen.dart';
import '../../features/coach/presentation/coach_result_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/subscription/presentation/paywall_screen.dart';
import '../../features/learning/presentation/missions_screen.dart';
import '../../features/trading/presentation/debug/buy_engine_debug_screen.dart';

const bool _buyEngineDebugHome = bool.fromEnvironment('BUY_ENGINE_DEBUG_HOME');

final GoRouter appRouter = createAppRouter(
  useBuyEngineDebugHome: kDebugMode && _buyEngineDebugHome,
);

GoRouter createAppRouter({
  bool includeDebugRoutes = kDebugMode,
  bool useBuyEngineDebugHome = false,
}) {
  return GoRouter(
    initialLocation: includeDebugRoutes && useBuyEngineDebugHome
        ? '/debug/buy-engine'
        : '/home',
    routes: [
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
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/markets',
        builder: (context, state) => const MarketsScreen(),
      ),
      GoRoute(
        path: '/asset/:symbol',
        builder: (context, state) => AssetDetailScreen(
          symbol: state.pathParameters['symbol'] ?? 'BTC',
        ),
      ),
      GoRoute(
        path: '/trade/:symbol',
        builder: (context, state) => TradeScreen(
          symbol: state.pathParameters['symbol'] ?? 'BTC',
        ),
      ),
      GoRoute(
        path: '/portfolio',
        builder: (context, state) => const PortfolioScreen(),
      ),
      GoRoute(
        path: '/trade-history',
        builder: (context, state) => const TradeHistoryScreen(),
      ),
      GoRoute(
        path: '/risk-meter',
        builder: (context, state) => const RiskMeterScreen(),
      ),
      GoRoute(
        path: '/discipline-meter',
        builder: (context, state) => const DisciplineMeterScreen(),
      ),
      GoRoute(
        path: '/coach-result/:tradeId',
        builder: (context, state) => CoachResultScreen(
          tradeId: state.pathParameters['tradeId'] ?? 'tr_mock_123',
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/missions',
        builder: (context, state) => const MissionsScreen(),
      ),
      if (includeDebugRoutes)
        GoRoute(
          path: '/debug/buy-engine',
          builder: (context, state) => const BuyEngineDebugScreen(),
        ),
    ],
  );
}
