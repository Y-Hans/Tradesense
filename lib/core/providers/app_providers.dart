import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/config/app_environment.dart';
import '../contracts/market_provider.dart';
import '../contracts/provider_contracts.dart';
import '../contracts/repository_contracts.dart';
import 'mocks/mock_repositories.dart';
import 'mocks/mock_market_repository.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/portfolio.dart';
import '../../shared/models/crypto_asset.dart';
import '../../shared/models/market_ticker.dart';
import '../../shared/models/subscription_status.dart';
import '../../shared/models/feature_flags.dart';

import '../../features/auth/data/supabase_auth_repository.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/application/user_lifecycle_notifier.dart';
import '../../features/onboarding/application/onboarding_notifier.dart';
import '../events/domain_event_providers.dart';

import '../../features/trading/data/supabase_trading_repository.dart';
import '../../features/portfolio/data/supabase_portfolio_repository.dart';
import '../../features/intelligence/data/supabase_intelligence_repository.dart';
import '../../features/subscription/data/revenue_cat_subscription_repository.dart';

export '../services/connectivity/connectivity_provider.dart';
export '../services/connectivity/connectivity_service.dart';
export '../services/connectivity/connectivity_status.dart';
export '../events/domain_event_providers.dart';

import '../../features/market/providers/market_cache_providers.dart';
/// Flag to toggle between Mock repository mode and Live backend mode
final mockModeProvider = StateProvider<bool>((ref) {
  final config = AppConfig.resolved();
  if (config.environment == AppEnvironment.production) {
    if (!config.isSupabaseConfigured) {
      throw StateError('FATAL: Production mode requires SUPABASE_URL and SUPABASE_ANON_KEY to be configured.');
    }
    return false; // Force false in production
  }
  return !config.isSupabaseConfigured;
});

final marketRepositoryProvider = Provider<MarketProvider>((ref) {
  final isMock = ref.watch(mockModeProvider);
  if (isMock) {
    return MockMarketRepository();
  }
  return ref.watch(cachedMarketRepositoryProvider);
});

final tradingRepositoryProvider = Provider<TradingRepository>((ref) {
  final marketRepo = ref.watch(marketRepositoryProvider);
  final eventPublisher = ref.watch(domainEventPublisherProvider);
  final isMock = ref.watch(mockModeProvider);
  
  if (isMock) {
    final repo = MockTradingRepository(marketRepo, eventPublisher: eventPublisher, initialBalance: 100000.0);
    ref.onDispose(() {
      repo.dispose();
    });
    return repo;
  }
  
  return SupabaseTradingRepository(eventPublisher: eventPublisher);
});

/// Portfolio Repository Provider
final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  final isMock = ref.watch(mockModeProvider);
  
  if (isMock) {
    final tradingRepo = ref.watch(tradingRepositoryProvider) as MockTradingRepository;
    return MockPortfolioRepository(tradingRepo);
  }
  
  final marketRepo = ref.watch(marketRepositoryProvider);
  return SupabasePortfolioRepository(marketRepo);
});

/// Intelligence Repository Provider
final intelligenceRepositoryProvider = Provider<IntelligenceRepository>((ref) {
  final eventPublisher = ref.watch(domainEventPublisherProvider);
  final isMock = ref.watch(mockModeProvider);
  
  if (isMock) {
    return MockIntelligenceRepository(eventPublisher);
  }
  
  return SupabaseIntelligenceRepository(eventPublisher: eventPublisher);
});

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final isMock = ref.watch(mockModeProvider);
  if (isMock) {
    return MockAuthRepository();
  }
  return SupabaseAuthRepository();
});

/// Auth State Provider (manages session lifecycle)
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final isMock = ref.watch(mockModeProvider);
  if (isMock) {
    return AuthNotifier(authRepo, authStateChanges: const Stream.empty());
  }
  return AuthNotifier(authRepo);
});

/// Subscription Provider
final subscriptionProvider = Provider<SubscriptionProvider>((ref) {
  final isMock = ref.watch(mockModeProvider);
  if (isMock || !AppConfig.resolved().isRevenueCatConfigured) {
    return MockSubscriptionRepository();
  }
  return RevenueCatSubscriptionRepository();
});

/// Remote Config Provider
final remoteConfigProvider = Provider<RemoteConfigProvider>((ref) {
  return MockRemoteConfigRepository();
});

/// Current User State Provider (wired to authStateProvider for seamless reactive access)
final currentUserProvider = Provider<AsyncValue<UserProfile?>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.isRestoring || authState.isAuthenticating) {
    return const AsyncValue.loading();
  }
  if (authState.hasError) {
    return AsyncValue.error(
        authState.errorMessage ?? 'Authentication error', StackTrace.current);
  }
  return AsyncValue.data(authState.user);
});

/// Current Portfolio State Provider
final portfolioProvider = FutureProvider<Portfolio>((ref) async {
  final portfolioRepo = ref.watch(portfolioRepositoryProvider);
  return portfolioRepo.getPortfolio();
});

/// Supported Crypto Assets Provider
final supportedAssetsProvider = FutureProvider<List<CryptoAsset>>((ref) async {
  final marketRepo = ref.watch(marketRepositoryProvider);
  return marketRepo.getSupportedAssets();
});

/// All Live Tickers Provider
final marketTickersProvider =
    FutureProvider<Map<String, MarketTicker>>((ref) async {
  final marketRepo = ref.watch(marketRepositoryProvider);
  return marketRepo.getAllTickers();
});

/// Subscription Status Provider
final subscriptionStatusProvider =
    FutureProvider<SubscriptionStatus>((ref) async {
  final subProvider = ref.watch(subscriptionProvider);
  return subProvider.getStatus();
});

/// User Lifecycle State Provider (tracks idempotent user initialization)
final userLifecycleProvider =
    StateNotifierProvider<UserLifecycleNotifier, UserLifecycleState>((ref) {
  final notifier = UserLifecycleNotifier();
  ref.listen<AuthState>(authStateProvider, (previous, next) {
    if (next.isAuthenticated && next.user != null) {
      notifier.initializeUser(next.user!);
    } else if (next.status == AuthStatus.unauthenticated) {
      notifier.reset();
    }
  });
  final currentAuth = ref.read(authStateProvider);
  if (currentAuth.isAuthenticated && currentAuth.user != null) {
    notifier.initializeUser(currentAuth.user!);
  }
  return notifier;
});

/// Onboarding State Provider (manages onboarding completion per user)
final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, void>((ref) {
  return OnboardingNotifier();
});

/// Feature Flags Provider
final featureFlagsProvider = FutureProvider<FeatureFlags>((ref) async {
  final configProvider = ref.watch(remoteConfigProvider);
  return configProvider.getFlags();
});
