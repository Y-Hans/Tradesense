import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/onboarding/presentation/disclaimer_screen.dart';
import '../../features/onboarding/presentation/profile_setup_screen.dart';
import '../../features/onboarding/presentation/risk_assessment_screen.dart';
import '../../features/onboarding/presentation/import_choice_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/today/presentation/today_screen.dart';
import '../../features/market/presentation/markets_screen.dart';
import '../../features/market/presentation/asset_detail_screen.dart';
import '../../features/portfolio/presentation/portfolio_screen.dart';
import '../../features/portfolio/presentation/trade_history_screen.dart';
import '../../features/learning/presentation/missions_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/coach/presentation/coach_result_screen.dart';
import '../../features/trading/presentation/trade_screen.dart';
import '../../features/intelligence/presentation/discipline_meter_screen.dart';
import '../../features/intelligence/presentation/risk_meter_screen.dart';

part 'app_router.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      // ── Pre-auth & onboarding flow ──────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/disclaimer',
        builder: (context, state) => const DisclaimerScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Onboarding steps (accessible after auth) ────────────────────────
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/risk-assessment',
        builder: (context, state) => const RiskAssessmentScreen(),
      ),
      GoRoute(
        path: '/import-choice',
        builder: (context, state) => const ImportChoiceScreen(),
      ),

      // ── Journal & Coach (full-screen, outside shell) ────────────────────
      GoRoute(
        path: '/journal',
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: '/trade-history',
        builder: (context, state) => const TradeHistoryScreen(),
      ),
      GoRoute(
        path: '/coach-result/:tradeId',
        builder: (context, state) {
          final tradeId = state.pathParameters['tradeId'] ?? '';
          return CoachResultScreen(tradeId: tradeId);
        },
      ),
      GoRoute(
        path: '/trade',
        builder: (context, state) {
          final symbol = (state.extra as String?) ?? 'BTCUSDT';
          return TradeScreen(symbol: symbol);
        },
      ),
      GoRoute(
        path: '/asset/:symbol',
        builder: (context, state) {
          final symbol = state.pathParameters['symbol'] ?? 'BTC';
          return AssetDetailScreen(symbol: symbol);
        },
      ),
      GoRoute(
        path: '/discipline-meter',
        builder: (context, state) => const DisciplineMeterScreen(),
      ),
      GoRoute(
        path: '/risk-meter',
        builder: (context, state) => const RiskMeterScreen(),
      ),

      // ── Main app shell with bottom nav ──────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const TodayScreen(),
          ),
          GoRoute(
            path: '/markets',
            builder: (context, state) => const MarketsScreen(),
          ),
          GoRoute(
            path: '/portfolio',
            builder: (context, state) => const PortfolioScreen(),
          ),
          GoRoute(
            path: '/missions',
            builder: (context, state) => const MissionsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
