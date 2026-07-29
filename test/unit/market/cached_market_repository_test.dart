import 'package:cryptoedu/core/cache/data/repositories/default_cache_repository.dart';
import 'package:cryptoedu/core/cache/data/storage/in_memory_cache_storage.dart';
import 'package:cryptoedu/core/cache/domain/contracts/cache_repository.dart';
import 'package:cryptoedu/core/cache/domain/models/cache_policy.dart';
import 'package:cryptoedu/core/contracts/market_provider.dart';
import 'package:cryptoedu/features/market/data/config/market_cache_policy.dart';
import 'package:cryptoedu/features/market/data/keys/market_cache_keys.dart';
import 'package:cryptoedu/features/market/data/repositories/cached_market_repository.dart';
import 'package:cryptoedu/features/market/data/serializers/market_serializers.dart';
import 'package:cryptoedu/shared/models/crypto_asset.dart';
import 'package:cryptoedu/shared/models/market_ticker.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMarketProvider implements MarketProvider {
  int getSupportedAssetsCallCount = 0;
  int getAllTickersCallCount = 0;
  int getTickerCallCount = 0;
  int getCandlesCallCount = 0;

  bool shouldThrow = false;
  Exception? customError;

  List<CryptoAsset> assetsResponse = const [
    CryptoAsset(
      symbol: 'BTC',
      name: 'Bitcoin',
      iconUrl: '',
      currentPriceInr: 5850000.0,
      change24hPercent: 2.5,
    ),
  ];

  Map<String, MarketTicker> tickersResponse = {};

  @override
  Future<List<CryptoAsset>> getSupportedAssets() async {
    getSupportedAssetsCallCount++;
    if (shouldThrow) throw customError ?? Exception('Network connection failed');
    return assetsResponse;
  }

  @override
  Future<Map<String, MarketTicker>> getAllTickers() async {
    getAllTickersCallCount++;
    if (shouldThrow) throw customError ?? Exception('Network connection failed');
    return tickersResponse;
  }

  @override
  Future<MarketTicker> getTicker(String symbol) async {
    getTickerCallCount++;
    if (shouldThrow) throw customError ?? Exception('Network connection failed');
    return MarketTicker(
      symbol: symbol,
      priceInr: 100.0,
      high24h: 105.0,
      low24h: 95.0,
      volume24h: 1000.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<List<MarketCandle>> getCandles(
    String symbol, {
    String interval = '1h',
    int limit = 100,
  }) async {
    getCandlesCallCount++;
    if (shouldThrow) throw customError ?? Exception('Network connection failed');
    return [
      MarketCandle(
        timestamp: DateTime.now(),
        open: 100.0,
        high: 110.0,
        low: 90.0,
        close: 105.0,
        volume: 5000.0,
      ),
    ];
  }

  @override
  Stream<MarketTicker> streamTicker(String symbol) {
    return Stream.value(
      MarketTicker(
        symbol: symbol,
        priceInr: 100.0,
        high24h: 105.0,
        low24h: 95.0,
        volume24h: 1000.0,
        timestamp: DateTime.now(),
      ),
    );
  }
}

void main() {
  group('MarketCacheKeys Tests', () {
    test('Formats key strings consistently and normalizes symbols to uppercase', () {
      expect(MarketCacheKeys.supportedAssets, equals('market_supported_assets'));
      expect(MarketCacheKeys.allTickers, equals('market_all_tickers'));
      expect(MarketCacheKeys.ticker('btc'), equals('market_ticker_BTC'));
      expect(
        MarketCacheKeys.candles('eth', '1h', 50),
        equals('market_candles_ETH_1h_50'),
      );
    });
  });

  group('CachedMarketRepository Unit Tests', () {
    late FakeMarketProvider fakeInner;
    late InMemoryCacheStorage storage;
    late DateTime fakeTime;
    late CacheRepository<List<CryptoAsset>> assetCache;
    late CacheRepository<Map<String, MarketTicker>> tickersMapCache;
    late CacheRepository<MarketTicker> tickerCache;
    late CacheRepository<List<MarketCandle>> candleCache;
    late CachedMarketRepository cachedRepo;

    setUp(() {
      fakeInner = FakeMarketProvider();
      storage = InMemoryCacheStorage();
      fakeTime = DateTime(2026, 7, 29, 12, 0, 0);

      assetCache = DefaultCacheRepository<List<CryptoAsset>>(
        storage: storage,
        serializer: CryptoAssetListSerializer(),
        clock: () => fakeTime,
      );
      tickersMapCache = DefaultCacheRepository<Map<String, MarketTicker>>(
        storage: storage,
        serializer: MarketTickersMapSerializer(),
        clock: () => fakeTime,
      );
      tickerCache = DefaultCacheRepository<MarketTicker>(
        storage: storage,
        serializer: MarketTickerSerializer(),
        clock: () => fakeTime,
      );
      candleCache = DefaultCacheRepository<List<MarketCandle>>(
        storage: storage,
        serializer: MarketCandleListSerializer(),
        clock: () => fakeTime,
      );

      cachedRepo = CachedMarketRepository(
        innerProvider: fakeInner,
        assetListCache: assetCache,
        tickersMapCache: tickersMapCache,
        tickerCache: tickerCache,
        candleListCache: candleCache,
        defaultPolicy: MarketCachePolicyDefaults.defaultPolicy,
      );
    });

    test('Cache Miss: Fetches from API and populates cache', () async {
      final assets = await cachedRepo.getSupportedAssets();

      expect(assets.length, equals(1));
      expect(assets.first.symbol, equals('BTC'));
      expect(fakeInner.getSupportedAssetsCallCount, equals(1));

      // Cache storage should contain key
      final exists = await assetCache.containsKey(MarketCacheKeys.supportedAssets);
      expect(exists, isTrue);
    });

    test('Cache Hit: Subsequent read returns cached data without calling API', () async {
      // First call (miss)
      await cachedRepo.getSupportedAssets();
      expect(fakeInner.getSupportedAssetsCallCount, equals(1));

      // Second call (hit)
      final cachedAssets = await cachedRepo.getSupportedAssets();
      expect(cachedAssets.length, equals(1));
      expect(cachedAssets.first.symbol, equals('BTC'));
      // API call count must remain 1
      expect(fakeInner.getSupportedAssetsCallCount, equals(1));
    });

    test('Expired Cache: Advance time beyond TTL triggers fresh API fetch', () async {
      // Warm up cache
      await cachedRepo.getSupportedAssets();
      expect(fakeInner.getSupportedAssetsCallCount, equals(1));

      // Advance clock past 5 minute TTL (6 minutes)
      fakeTime = fakeTime.add(const Duration(minutes: 6));
      fakeInner.assetsResponse = const [
        CryptoAsset(
          symbol: 'ETH',
          name: 'Ethereum',
          iconUrl: '',
          currentPriceInr: 300000.0,
          change24hPercent: 3.0,
        ),
      ];

      final refreshedAssets = await cachedRepo.getSupportedAssets();

      expect(refreshedAssets.first.symbol, equals('ETH'));
      expect(fakeInner.getSupportedAssetsCallCount, equals(2));
    });

    test('Stale Cache Fallback: Returns stale cached data when API fails and allowStale is true', () async {
      // Warm up cache at t0
      await cachedRepo.getSupportedAssets();
      expect(fakeInner.getSupportedAssetsCallCount, equals(1));

      // Advance clock past TTL and simulate API failure
      fakeTime = fakeTime.add(const Duration(minutes: 10));
      fakeInner.shouldThrow = true;

      // Should return stale BTC data instead of throwing exception
      final fallbackAssets = await cachedRepo.getSupportedAssets();
      expect(fallbackAssets.length, equals(1));
      expect(fallbackAssets.first.symbol, equals('BTC'));
      expect(fakeInner.getSupportedAssetsCallCount, equals(2));
    });

    test('API Failure Without Cache: Rethrows exception when no cache is available', () async {
      fakeInner.shouldThrow = true;

      expect(
        () async => await cachedRepo.getSupportedAssets(),
        throwsA(isA<Exception>()),
      );
    });

    test('Cache Version Mismatch: Schema evolution invalidates old version and refreshes from API', () async {
      // Seed cache directly with old version 'v0'
      const oldPolicy = CachePolicy(ttl: Duration(minutes: 60), version: 'v0');
      await assetCache.set(
        MarketCacheKeys.supportedAssets,
        const [
          CryptoAsset(
            symbol: 'XRP',
            name: 'XRP Old',
            iconUrl: '',
            currentPriceInr: 40.0,
            change24hPercent: 0.0,
          ),
        ],
        policy: oldPolicy,
      );

      // cachedRepo uses 'v1' policy default
      final assets = await cachedRepo.getSupportedAssets();

      // Should detect version mismatch, call API, update cache to 'v1', return BTC
      expect(assets.first.symbol, equals('BTC'));
      expect(fakeInner.getSupportedAssetsCallCount, equals(1));
    });

    test('Cache Version Mismatch with API Failure: Falls back to stale entry when allowStale is true', () async {
      // Seed cache directly with old version 'v0'
      const oldPolicy = CachePolicy(ttl: Duration(minutes: 60), version: 'v0');
      await assetCache.set(
        MarketCacheKeys.supportedAssets,
        const [
          CryptoAsset(
            symbol: 'SOL',
            name: 'Solana Stale',
            iconUrl: '',
            currentPriceInr: 12000.0,
            change24hPercent: 1.0,
          ),
        ],
        policy: oldPolicy,
      );

      fakeInner.shouldThrow = true;

      // Version mismatch occurs + API fails -> returns stale 'SOL' entry
      final assets = await cachedRepo.getSupportedAssets();
      expect(assets.first.symbol, equals('SOL'));
      expect(fakeInner.getSupportedAssetsCallCount, equals(1));
    });

    test('Stream Ticker: Delegates directly to inner provider without cache side-effects', () async {
      final stream = cachedRepo.streamTicker('BTC');
      final ticker = await stream.first;

      expect(ticker.symbol, equals('BTC'));
      expect(ticker.priceInr, equals(100.0));

      // Ticker cache should NOT contain key from stream emission
      final hasKey = await tickerCache.containsKey(MarketCacheKeys.ticker('BTC'));
      expect(hasKey, isFalse);
    });

    test('Ticker & Candle Cache operations operate correctly through generic repository', () async {
      final ticker = await cachedRepo.getTicker('BTC');
      expect(ticker.symbol, equals('BTC'));
      expect(fakeInner.getTickerCallCount, equals(1));

      // Second getTicker call hits cache
      await cachedRepo.getTicker('BTC');
      expect(fakeInner.getTickerCallCount, equals(1));

      // GetCandles
      final candles = await cachedRepo.getCandles('BTC', interval: '1h', limit: 100);
      expect(candles.length, equals(1));
      expect(fakeInner.getCandlesCallCount, equals(1));

      // Second getCandles call hits cache
      await cachedRepo.getCandles('BTC', interval: '1h', limit: 100);
      expect(fakeInner.getCandlesCallCount, equals(1));
    });
  });
}
