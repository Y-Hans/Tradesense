/// Centralized cache keys for Market domain data.
class MarketCacheKeys {
  MarketCacheKeys._();

  /// Cache key for supported crypto assets list.
  static const String supportedAssets = 'market_supported_assets';

  /// Cache key for all market tickers map.
  static const String allTickers = 'market_all_tickers';

  /// Returns cache key for single ticker by [symbol].
  static String ticker(String symbol) =>
      'market_ticker_${symbol.toUpperCase()}';

  /// Returns cache key for candle series by [symbol], [interval], and [limit].
  static String candles(String symbol, String interval, int limit) =>
      'market_candles_${symbol.toUpperCase()}_${interval}_$limit';
}
