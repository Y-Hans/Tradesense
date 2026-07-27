import '../../shared/models/crypto_asset.dart';
import '../../shared/models/market_ticker.dart';

abstract class MarketProvider {
  Future<List<CryptoAsset>> getSupportedAssets();
  Future<MarketTicker> getTicker(String symbol);
  Future<Map<String, MarketTicker>> getAllTickers();
  Future<List<MarketCandle>> getCandles(String symbol,
      {String interval = '1h', int limit = 100});
  Stream<MarketTicker> streamTicker(String symbol);
}
