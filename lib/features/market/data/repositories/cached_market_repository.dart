import '../../../../core/contracts/market_provider.dart';
import '../../../../core/cache/domain/contracts/cache_repository.dart';
import '../../../../core/cache/domain/models/cache_policy.dart';
import '../../../../core/cache/domain/models/cache_result.dart';
import '../../../../shared/models/crypto_asset.dart';
import '../../../../shared/models/market_ticker.dart';
import '../config/market_cache_policy.dart';
import '../keys/market_cache_keys.dart';

/// Implementation of [MarketProvider] leveraging generic [CacheRepository] infrastructure.
///
/// Serves as the single source of truth for market data, wrapping an inner [MarketProvider]
/// (remote/mock backend) and enforcing a deterministic cache-first flow with stale fallback.
class CachedMarketRepository implements MarketProvider {
  final MarketProvider _innerProvider;
  final CacheRepository<List<CryptoAsset>> _assetListCache;
  final CacheRepository<Map<String, MarketTicker>> _tickersMapCache;
  final CacheRepository<MarketTicker> _tickerCache;
  final CacheRepository<List<MarketCandle>> _candleListCache;
  final CachePolicy _defaultPolicy;

  CachedMarketRepository({
    required MarketProvider innerProvider,
    required CacheRepository<List<CryptoAsset>> assetListCache,
    required CacheRepository<Map<String, MarketTicker>> tickersMapCache,
    required CacheRepository<MarketTicker> tickerCache,
    required CacheRepository<List<MarketCandle>> candleListCache,
    CachePolicy? defaultPolicy,
  })  : _innerProvider = innerProvider,
        _assetListCache = assetListCache,
        _tickersMapCache = tickersMapCache,
        _tickerCache = tickerCache,
        _candleListCache = candleListCache,
        _defaultPolicy = defaultPolicy ?? MarketCachePolicyDefaults.defaultPolicy;

  @override
  Future<List<CryptoAsset>> getSupportedAssets({CachePolicy? policy}) async {
    return _getOrFetch<List<CryptoAsset>>(
      key: MarketCacheKeys.supportedAssets,
      cacheRepo: _assetListCache,
      apiFetcher: () => _innerProvider.getSupportedAssets(),
      policy: policy,
    );
  }

  @override
  Future<Map<String, MarketTicker>> getAllTickers({CachePolicy? policy}) async {
    return _getOrFetch<Map<String, MarketTicker>>(
      key: MarketCacheKeys.allTickers,
      cacheRepo: _tickersMapCache,
      apiFetcher: () => _innerProvider.getAllTickers(),
      policy: policy,
    );
  }

  @override
  Future<MarketTicker> getTicker(String symbol, {CachePolicy? policy}) async {
    return _getOrFetch<MarketTicker>(
      key: MarketCacheKeys.ticker(symbol),
      cacheRepo: _tickerCache,
      apiFetcher: () => _innerProvider.getTicker(symbol),
      policy: policy,
    );
  }

  @override
  Future<List<MarketCandle>> getCandles(
    String symbol, {
    String interval = '1h',
    int limit = 100,
    CachePolicy? policy,
  }) async {
    return _getOrFetch<List<MarketCandle>>(
      key: MarketCacheKeys.candles(symbol, interval, limit),
      cacheRepo: _candleListCache,
      apiFetcher: () => _innerProvider.getCandles(
        symbol,
        interval: interval,
        limit: limit,
      ),
      policy: policy,
    );
  }

  @override
  Stream<MarketTicker> streamTicker(String symbol) {
    // Per requirement: Delegate streaming directly without mutating cache
    return _innerProvider.streamTicker(symbol);
  }

  /// Generic helper enforcing the deterministic caching strategy:
  /// 1. Read cache. If valid hit (not expired), return cached value.
  /// 2. If miss or expired, fetch from API.
  /// 3. If API fetch succeeds, update cache and return fresh value.
  /// 4. If API fetch fails and stale cache exists (and allowed), return stale value.
  /// 5. If API fetch fails and no cache exists, rethrow exception.
  Future<T> _getOrFetch<T>({
    required String key,
    required CacheRepository<T> cacheRepo,
    required Future<T> Function() apiFetcher,
    CachePolicy? policy,
  }) async {
    final effectivePolicy = policy ?? _defaultPolicy;

    // Read existing cache entry
    final cacheResult = await cacheRepo.get(key, policy: effectivePolicy);

    // Valid non-expired cache hit
    if (cacheResult is CacheHit<T> && !cacheResult.isStale) {
      return cacheResult.value;
    }

    // Stale fallback payload from expired entry (if present)
    final staleValue = cacheResult.dataOrNull;

    // Fetch fresh data from network/API
    try {
      final freshData = await apiFetcher();
      await cacheRepo.set(key, freshData, policy: effectivePolicy);
      return freshData;
    } catch (error) {
      // Fallback to stale cached data if policy allows and stale value is available
      if (effectivePolicy.allowStale && staleValue != null) {
        return staleValue;
      }
      rethrow;
    }
  }
}
