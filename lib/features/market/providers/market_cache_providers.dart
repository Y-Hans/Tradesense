import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/dio_client_factory.dart';
import '../../../core/networking/binance/binance_rest_client.dart';
import '../../../core/networking/binance/binance_ws_client.dart';
import '../../../core/networking/coingecko/coingecko_client.dart';
import '../../../core/networking/binance_market_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/cache/domain/models/cache_policy.dart';
import '../../../core/cache/providers/cache_providers.dart';
import '../../../core/contracts/market_provider.dart';
import '../../../core/providers/mocks/mock_market_repository.dart';
import '../../../shared/models/crypto_asset.dart';
import '../../../shared/models/market_ticker.dart';
import '../data/config/market_cache_policy.dart';
import '../data/repositories/cached_market_repository.dart';
import '../data/serializers/market_serializers.dart';

/// Provider for default market cache policy configuration.
final marketCachePolicyProvider = Provider<CachePolicy>((ref) {
  return MarketCachePolicyDefaults.defaultPolicy;
});

/// Cache repository provider for `List<CryptoAsset>`.
final cryptoAssetListCacheRepositoryProvider =
    createCacheRepositoryProvider<List<CryptoAsset>>(
  serializer: CryptoAssetListSerializer(),
);

/// Cache repository provider for `Map<String, MarketTicker>`.
final marketTickersMapCacheRepositoryProvider =
    createCacheRepositoryProvider<Map<String, MarketTicker>>(
  serializer: MarketTickersMapSerializer(),
);

/// Cache repository provider for single `MarketTicker`.
final marketTickerCacheRepositoryProvider =
    createCacheRepositoryProvider<MarketTicker>(
  serializer: MarketTickerSerializer(),
);

/// Cache repository provider for `List<MarketCandle>`.
final marketCandleListCacheRepositoryProvider =
    createCacheRepositoryProvider<List<MarketCandle>>(
  serializer: MarketCandleListSerializer(),
);

/// Provider exposing [CachedMarketRepository] initialized with generic cache repositories.
final cachedMarketRepositoryProvider = Provider<MarketProvider>((ref) {
  final isMock = ref.watch(mockModeProvider);
  
  MarketProvider innerProvider;
  if (isMock) {
    innerProvider = MockMarketRepository();
  } else {
    BinanceMarketProvider? providerRef;
    final provider = BinanceMarketProvider(
      binanceRest: BinanceRestClient(
        dio: DioClientFactory.forBinanceRest(),
        usdToInrRate: () => providerRef?.usdToInrRate ?? 83.5,
      ),
      binanceWs: BinanceWebSocketClient(
        usdToInrRate: () => providerRef?.usdToInrRate ?? 83.5,
      ),
      coinGecko: CoinGeckoClient(dio: DioClientFactory.forCoinGecko()),
      initialUsdToInrRate: 83.5,
    );
    providerRef = provider;
    provider.startRateRefresh();
    ref.onDispose(() => provider.dispose());
    innerProvider = provider;
  }

  return CachedMarketRepository(
    innerProvider: innerProvider,
    assetListCache: ref.watch(cryptoAssetListCacheRepositoryProvider),
    tickersMapCache: ref.watch(marketTickersMapCacheRepositoryProvider),
    tickerCache: ref.watch(marketTickerCacheRepositoryProvider),
    candleListCache: ref.watch(marketCandleListCacheRepositoryProvider),
    defaultPolicy: ref.watch(marketCachePolicyProvider),
  );
});
