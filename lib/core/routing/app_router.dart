import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/app_providers.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/onboarding/presentation/disclaimer_screen.dart';
import '../../features/onboarding/presentation/profile_setup_screen.dart';
import '../../features/onboarding/presentation/risk_assessment_screen.dart';
import '../../features/onboarding/presentation/import_choice_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/email_verification_screen.dart';
import '../../features/auth/presentation/password_reset_verification_screen.dart';
import '../../features/auth/presentation/set_new_password_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/today/presentation/today_screen.dart';
import '../../features/market/presentation/markets_screen.dart';
import '../../features/market/presentation/asset_detail_screen.dart';
import '../../features/market/presentation/currency_converter_screen.dart';
import '../../features/portfolio/presentation/portfolio_screen.dart';
import '../../features/portfolio/presentation/trade_history_screen.dart';
import '../../features/learning/presentation/missions_screen.dart';
import '../../features/learning/presentation/news_detective_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/coach/presentation/coach_screen.dart';
import '../../features/coach/presentation/coach_result_screen.dart';
import '../../features/trading/presentation/trade_screen.dart';
import '../../features/intelligence/presentation/discipline_meter_screen.dart';
import '../../features/intelligence/presentation/risk_meter_screen.dart';
import '../../features/subscription/presentation/paywall_screen.dart';

part 'app_router.g.dart';

class RouterListenable extends ChangeNotifier {
  final Ref _ref;

  RouterListenable(this._ref) {
    _ref.listen<AuthState>(authStateProvider, (_, __) => notifyListeners());
    _ref.listen<void>(
        onboardingNotifierProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);

    if (authState.isRestoring) {
      return null;
    }

    final loc = state.matchedLocation;
    final isAuthRoute = loc == '/login' || loc == '/register' || loc == '/welcome' || loc == '/disclaimer' || loc == '/forgot-password' || loc == '/verify-email' || loc == '/verify-reset-password' || loc == '/set-new-password';
    final isOnboardingRoute = loc == '/onboarding' || loc == '/profile-setup' || loc == '/risk-assessment' || loc == '/import-choice';
    final isSplash = loc == '/splash';
    
    // Convert root access to home
    if (loc == '/') return '/home';

    if (!authState.isAuthenticated && !authState.isAuthenticating) {
      // Protect recovery routes: only allow if we are actively resetting password
      if (loc == '/set-new-password' && authState.status != AuthStatus.resettingPassword) {
        return '/login';
      }
      
      if (isAuthRoute || isSplash) return null;
      return '/login';
    }

    if (authState.isAuthenticated) {
      final user = authState.user;
      final onboardingNotifier = _ref.read(onboardingNotifierProvider.notifier);
      final onboardingDone = onboardingNotifier.isCompleted(user?.id);

      if (!onboardingDone) {
        if (isOnboardingRoute || isSplash) return null;
        return '/onboarding';
      } else {
        if (isAuthRoute || isOnboardingRoute || isSplash) {
          return '/home';
        }
        return null;
      }
    }

    return null;
  }
}

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorHomeKey =
    GlobalKey<NavigatorState>(debugLabel: 'home');
final GlobalKey<NavigatorState> _shellNavigatorMarketsKey =
    GlobalKey<NavigatorState>(debugLabel: 'markets');
final GlobalKey<NavigatorState> _shellNavigatorPortfolioKey =
    GlobalKey<NavigatorState>(debugLabel: 'portfolio');
final GlobalKey<NavigatorState> _shellNavigatorCoachKey =
    GlobalKey<NavigatorState>(debugLabel: 'coach');
final GlobalKey<NavigatorState> _shellNavigatorMissionsKey =
    GlobalKey<NavigatorState>(debugLabel: 'missions');
final GlobalKey<NavigatorState> _shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'profile');

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final listenable = RouterListenable(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: listenable,
    redirect: listenable.redirect,
    routes: [
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
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/verify-reset-password',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return PasswordResetVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/set-new-password',
        builder: (context, state) => const SetNewPasswordScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
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
      GoRoute(
        path: '/journal',
        builder: (context, state) => JournalScreen(),
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
        path: '/trade/:symbol',
        builder: (context, state) {
          final symbol = state.pathParameters['symbol'] ?? 'BTCUSDT';
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
        path: '/currency-converter',
        builder: (context, state) => const CurrencyConverterScreen(),
      ),
      GoRoute(
        path: '/discipline-meter',
        builder: (context, state) => const DisciplineMeterScreen(),
      ),
      GoRoute(
        path: '/risk-meter',
        builder: (context, state) => const RiskMeterScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/news-detective',
        builder: (context, state) => const NewsDetectiveScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const TodayScreen(),
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
            navigatorKey: _shellNavigatorPortfolioKey,
            routes: [
              GoRoute(
                path: '/portfolio',
                builder: (context, state) => const PortfolioScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCoachKey,
            routes: [
              GoRoute(
                path: '/coach',
                builder: (context, state) => const CoachScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMissionsKey,
            routes: [
              GoRoute(
                path: '/missions',
                builder: (context, state) => const MissionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
