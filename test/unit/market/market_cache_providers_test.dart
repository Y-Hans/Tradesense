import 'package:cryptoedu/core/providers/app_providers.dart';
import 'package:cryptoedu/features/market/data/config/market_cache_policy.dart';
import 'package:cryptoedu/features/market/data/repositories/cached_market_repository.dart';
import 'package:cryptoedu/features/market/providers/market_cache_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Market Cache Providers Unit Tests', () {
    test('marketCachePolicyProvider returns default market policy', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final policy = container.read(marketCachePolicyProvider);
      expect(policy.ttl, equals(MarketCachePolicyDefaults.defaultTtl));
      expect(policy.allowStale, isTrue);
      expect(policy.version, equals(MarketCachePolicyDefaults.currentVersion));
    });

    test(
        'cachedMarketRepositoryProvider builds CachedMarketRepository instance',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(cachedMarketRepositoryProvider);
      expect(repo, isA<CachedMarketRepository>());
    });

    test('live app marketRepositoryProvider resolves to cached repository', () {
      final container = ProviderContainer(
        overrides: [
          mockModeProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(marketRepositoryProvider);
      expect(repo, isA<CachedMarketRepository>());
    });

    test(
        'supportedAssetsProvider seamlessly fetches data via cached repository',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final assets = await container.read(supportedAssetsProvider.future);
      expect(assets, isNotEmpty);
      expect(assets.first.symbol, equals('BTC'));
    });

    test(
        'marketTickersProvider seamlessly fetches tickers via cached repository',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final tickers = await container.read(marketTickersProvider.future);
      expect(tickers, isNotEmpty);
      expect(tickers.containsKey('BTC'), isTrue);
    });
  });
}
