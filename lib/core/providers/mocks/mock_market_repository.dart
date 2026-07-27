import 'dart:async';
import '../../contracts/market_provider.dart';
import '../../../shared/models/crypto_asset.dart';
import '../../../shared/models/market_ticker.dart';

class MockMarketRepository implements MarketProvider {
  final Map<String, MarketTicker> _tickers = {
    'BTC': MarketTicker(
      symbol: 'BTC',
      priceInr: 5850000.0,
      high24h: 5950000.0,
      low24h: 5720000.0,
      volume24h: 124500000.0,
      timestamp: DateTime.now(),
    ),
    'ETH': MarketTicker(
      symbol: 'ETH',
      priceInr: 295000.0,
      high24h: 305000.0,
      low24h: 288000.0,
      volume24h: 85000000.0,
      timestamp: DateTime.now(),
    ),
    'SOL': MarketTicker(
      symbol: 'SOL',
      priceInr: 12800.0,
      high24h: 13400.0,
      low24h: 12100.0,
      volume24h: 42000000.0,
      timestamp: DateTime.now(),
    ),
    'XRP': MarketTicker(
      symbol: 'XRP',
      priceInr: 48.5,
      high24h: 51.2,
      low24h: 46.8,
      volume24h: 31000000.0,
      timestamp: DateTime.now(),
    ),
    'BNB': MarketTicker(
      symbol: 'BNB',
      priceInr: 48500.0,
      high24h: 49800.0,
      low24h: 47200.0,
      volume24h: 19000000.0,
      timestamp: DateTime.now(),
    ),
  };

  @override
  Future<List<CryptoAsset>> getSupportedAssets() async {
    return const [
      CryptoAsset(
          symbol: 'BTC',
          name: 'Bitcoin',
          iconUrl: 'assets/icons/btc.png',
          currentPriceInr: 5850000.0,
          change24hPercent: 2.4),
      CryptoAsset(
          symbol: 'ETH',
          name: 'Ethereum',
          iconUrl: 'assets/icons/eth.png',
          currentPriceInr: 295000.0,
          change24hPercent: -1.2),
      CryptoAsset(
          symbol: 'SOL',
          name: 'Solana',
          iconUrl: 'assets/icons/sol.png',
          currentPriceInr: 12800.0,
          change24hPercent: 5.8),
      CryptoAsset(
          symbol: 'XRP',
          name: 'XRP',
          iconUrl: 'assets/icons/xrp.png',
          currentPriceInr: 48.5,
          change24hPercent: 0.8),
      CryptoAsset(
          symbol: 'BNB',
          name: 'BNB',
          iconUrl: 'assets/icons/bnb.png',
          currentPriceInr: 48500.0,
          change24hPercent: 1.1),
    ];
  }

  @override
  Future<MarketTicker> getTicker(String symbol) async {
    return _tickers[symbol] ??
        MarketTicker(
          symbol: symbol,
          priceInr: 100.0,
          high24h: 105.0,
          low24h: 95.0,
          volume24h: 1000000.0,
          timestamp: DateTime.now(),
        );
  }

  @override
  Future<Map<String, MarketTicker>> getAllTickers() async =>
      Map.unmodifiable(_tickers);

  @override
  Future<List<MarketCandle>> getCandles(String symbol,
      {String interval = '1h', int limit = 100}) async {
    final now = DateTime.now();
    final basePrice = _tickers[symbol]?.priceInr ?? 100.0;
    return List.generate(24, (i) {
      final time = now.subtract(Duration(hours: 24 - i));
      final variation = (i % 2 == 0 ? 1 : -1) * (i * 0.005) * basePrice;
      return MarketCandle(
        timestamp: time,
        open: basePrice + variation - 10,
        high: basePrice + variation + 50,
        low: basePrice + variation - 50,
        close: basePrice + variation,
        volume: 10000.0 + (i * 500),
      );
    });
  }

  @override
  Stream<MarketTicker> streamTicker(String symbol) {
    return Stream.periodic(const Duration(seconds: 5), (_) {
      final current = _tickers[symbol] ??
          MarketTicker(
              symbol: symbol,
              priceInr: 100,
              high24h: 105,
              low24h: 95,
              volume24h: 10000,
              timestamp: DateTime.now());
      return MarketTicker(
        symbol: symbol,
        priceInr: current.priceInr * 1.001,
        high24h: current.high24h,
        low24h: current.low24h,
        volume24h: current.volume24h,
        timestamp: DateTime.now(),
      );
    });
  }
}
