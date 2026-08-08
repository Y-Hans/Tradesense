import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../contracts/market_provider.dart';
import '../contracts/provider_contracts.dart';
import '../contracts/repository_contracts.dart';
import 'mocks/mock_market_repository.dart';
import 'mocks/mock_repositories.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/portfolio.dart';
import '../../shared/models/crypto_asset.dart';
import '../../shared/models/market_ticker.dart';
import '../../shared/models/subscription_status.dart';
import '../../shared/models/feature_flags.dart';

import '../../features/auth/data/supabase_auth_repository.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/application/auth_notifier.dart';
import '../../features/trading/data/supabase_trading_repository.dart';

enum ConnectivityStatus { online, offline }

final connectivityProvider = StateProvider<ConnectivityStatus>((ref) => ConnectivityStatus.online);

/// Flag to toggle between Mock repository mode and Live backend mode
final mockModeProvider = StateProvider<bool>((ref) => true);

/// Market Provider
final marketRepositoryProvider = Provider<MarketProvider>((ref) {
  return MockMarketRepository();
});

final tradingRepositoryProvider = Provider<TradingRepository>((ref) {
  final isMock = ref.watch(mockModeProvider);
  if (isMock) {
    final marketRepo = ref.watch(marketRepositoryProvider);
    final repo = MockTradingRepository(marketRepo, initialBalance: 100000.0);
    ref.onDispose(() {
      repo.dispose();
    });
    return repo;
  }
  return SupabaseTradingRepository();
});

/// Portfolio Repository Provider
final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  final tradingRepo =
      ref.watch(tradingRepositoryProvider) as MockTradingRepository;
  return MockPortfolioRepository(tradingRepo);
});

/// Intelligence Repository Provider
final intelligenceRepositoryProvider = Provider<IntelligenceRepository>((ref) {
  return MockIntelligenceRepository();
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
  return AuthNotifier(authRepo);
});

/// Subscription Provider
final subscriptionProvider = Provider<SubscriptionProvider>((ref) {
  return MockSubscriptionRepository();
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

/// Feature Flags Provider
final featureFlagsProvider = FutureProvider<FeatureFlags>((ref) async {
  final configProvider = ref.watch(remoteConfigProvider);
  return configProvider.getFlags();
});
