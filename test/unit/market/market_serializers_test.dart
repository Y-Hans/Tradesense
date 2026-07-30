import 'package:cryptoedu/core/cache/domain/models/cache_entry.dart';
import 'package:cryptoedu/features/market/data/serializers/market_serializers.dart';
import 'package:cryptoedu/shared/models/crypto_asset.dart';
import 'package:cryptoedu/shared/models/market_ticker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Market Cache Serializers Unit Tests', () {
    final now = DateTime(2026, 7, 29, 12, 0, 0);

    test('CryptoAssetListSerializer serializes and deserializes correctly', () {
      final serializer = CryptoAssetListSerializer();
      final assets = [
        const CryptoAsset(
          symbol: 'BTC',
          name: 'Bitcoin',
          iconUrl: 'assets/icons/btc.png',
          currentPriceInr: 5850000.0,
          change24hPercent: 2.4,
        ),
        const CryptoAsset(
          symbol: 'ETH',
          name: 'Ethereum',
          iconUrl: 'assets/icons/eth.png',
          currentPriceInr: 295000.0,
          change24hPercent: -1.2,
        ),
      ];

      final entry = CacheEntry<List<CryptoAsset>>(
        key: 'test_assets',
        value: assets,
        createdAt: now,
        ttl: const Duration(minutes: 5),
        version: 'v1',
      );

      final serialized = serializer.serialize(entry);
      final deserialized = serializer.deserialize(serialized);

      expect(deserialized.key, equals('test_assets'));
      expect(deserialized.createdAt, equals(now));
      expect(deserialized.ttl, equals(const Duration(minutes: 5)));
      expect(deserialized.version, equals('v1'));
      expect(deserialized.value.length, equals(2));
      expect(deserialized.value[0].symbol, equals('BTC'));
      expect(deserialized.value[0].currentPriceInr, equals(5850000.0));
      expect(deserialized.value[1].symbol, equals('ETH'));
    });

    test('MarketTickersMapSerializer serializes and deserializes correctly',
        () {
      final serializer = MarketTickersMapSerializer();
      final tickers = {
        'SOL': MarketTicker(
          symbol: 'SOL',
          priceInr: 12800.0,
          high24h: 13400.0,
          low24h: 12100.0,
          volume24h: 42000000.0,
          timestamp: now,
        ),
      };

      final entry = CacheEntry<Map<String, MarketTicker>>(
        key: 'test_tickers',
        value: tickers,
        createdAt: now,
      );

      final serialized = serializer.serialize(entry);
      final deserialized = serializer.deserialize(serialized);

      expect(deserialized.value.containsKey('SOL'), isTrue);
      expect(deserialized.value['SOL']!.priceInr, equals(12800.0));
      expect(deserialized.value['SOL']!.timestamp, equals(now));
    });

    test('MarketTickerSerializer serializes and deserializes correctly', () {
      final serializer = MarketTickerSerializer();
      final ticker = MarketTicker(
        symbol: 'XRP',
        priceInr: 48.5,
        high24h: 51.2,
        low24h: 46.8,
        volume24h: 31000000.0,
        timestamp: now,
      );

      final entry = CacheEntry<MarketTicker>(
        key: 'test_ticker',
        value: ticker,
        createdAt: now,
      );

      final serialized = serializer.serialize(entry);
      final deserialized = serializer.deserialize(serialized);

      expect(deserialized.value.symbol, equals('XRP'));
      expect(deserialized.value.priceInr, equals(48.5));
    });

    test('MarketCandleListSerializer serializes and deserializes correctly',
        () {
      final serializer = MarketCandleListSerializer();
      final candles = [
        MarketCandle(
          timestamp: now,
          open: 100.0,
          high: 110.0,
          low: 95.0,
          close: 105.0,
          volume: 5000.0,
        ),
      ];

      final entry = CacheEntry<List<MarketCandle>>(
        key: 'test_candles',
        value: candles,
        createdAt: now,
      );

      final serialized = serializer.serialize(entry);
      final deserialized = serializer.deserialize(serialized);

      expect(deserialized.value.length, equals(1));
      expect(deserialized.value[0].close, equals(105.0));
    });
  });
}
