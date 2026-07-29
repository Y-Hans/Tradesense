import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../contracts/market_provider.dart';
import '../contracts/provider_contracts.dart';
import '../contracts/repository_contracts.dart';
import 'mocks/mock_repositories.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/portfolio.dart';
import '../../shared/models/crypto_asset.dart';
import '../../shared/models/market_ticker.dart';
import '../../shared/models/subscription_status.dart';
import '../../shared/models/feature_flags.dart';

export '../services/connectivity/connectivity_provider.dart';
export '../services/connectivity/connectivity_service.dart';
export '../services/connectivity/connectivity_status.dart';


import '../../features/market/providers/market_cache_providers.dart';

/// Flag to toggle between Mock repository mode and Live backend mode
final mockModeProvider = StateProvider<bool>((ref) => true);

/// Market Provider
final marketRepositoryProvider = Provider<MarketProvider>((ref) {
  return ref.watch(cachedMarketRepositoryProvider);
});

/// Trading Repository Provider
final tradingRepositoryProvider = Provider<TradingRepository>((ref) {
  return MockTradingRepository();
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
  return MockAuthRepository();
});

/// Subscription Provider
final subscriptionProvider = Provider<SubscriptionProvider>((ref) {
  return MockSubscriptionRepository();
});

/// Remote Config Provider
final remoteConfigProvider = Provider<RemoteConfigProvider>((ref) {
  return MockRemoteConfigRepository();
});

/// Current User State Provider
final currentUserProvider = FutureProvider<UserProfile?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getCurrentUser();
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
