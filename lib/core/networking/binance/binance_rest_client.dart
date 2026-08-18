import 'package:dio/dio.dart';
import '../../../shared/models/crypto_asset.dart';
import '../../../shared/models/market_ticker.dart';
import '../../pricing/market_pricing.dart';

/// Binance public REST API client.
///
/// Covers only the market-data endpoints required by [MarketProvider]:
/// - `/api/v3/ticker/24hr` — 24-hour statistics (price, high, low, volume)
/// - `/api/v3/klines`       — Candlestick / OHLCV data
///
/// No API key is required for these endpoints.  The client works against the
/// live Binance production cluster at `https://api.binance.com`.
///
/// ## Currency conversion
/// Pair selection is discovered from Binance exchange metadata. Direct INR
/// pairs are preferred; non-INR pairs require a current injected FX rate.
///
/// ## Usage
/// Obtain an instance through the Riverpod provider rather than constructing
/// directly — see `market_api_provider.dart`.
class BinanceRestClient {
  BinanceRestClient({
    required Dio dio,
    required double? Function(String quoteCurrency) fxRateForQuote,
  })  : _dio = dio,
        _fxRateForQuote = fxRateForQuote;

  final Dio _dio;
  final double? Function(String quoteCurrency) _fxRateForQuote;

  // ---------------------------------------------------------------------------
  // Supported quotes, ordered by product policy.
  // ---------------------------------------------------------------------------

  /// Maps our canonical symbol (e.g. `'BTC'`) to its Binance trading pair
  /// (e.g. `'BTCUSDT'`).
  static const List<String> _quotePriority = ['INR', 'USDT', 'USDC', 'USD'];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns a [MarketTicker] for [symbol] (e.g. `'BTC'`).
  ///
  /// Fetches 24-hour statistics from a discovered pair and converts to INR
  /// only when the quote is not already INR.
  ///
  /// Throws [ArgumentError] if [symbol] is not in the supported set.
  /// Throws [DioException] on network failure (after retries).
  Future<MarketTicker> getTicker(String symbol) async {
    final pair = await resolvePair(symbol);
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v3/ticker/24hr',
      queryParameters: {'symbol': pair.exchangeSymbol},
    );
    return _parseTicker(symbol.toUpperCase(), pair, response.data!);
  }

  /// Returns 24-hour statistics for all supported symbols in one batch call.
  ///
  /// Uses the array-form of `/api/v3/ticker/24hr` so that a single round-trip
  /// fetches all pairs.
  Future<Map<String, MarketTicker>> getAllTickers() async {
    final pairsByAsset = await resolveAllPairs();
    final pairs =
        pairsByAsset.values.map((pair) => pair.exchangeSymbol).toList();
    final symbols = '[${pairs.map((p) => '"$p"').join(',')}]';

    final response = await _dio.get<List<dynamic>>(
      '/api/v3/ticker/24hr',
      queryParameters: {'symbols': symbols},
    );

    final result = <String, MarketTicker>{};
    for (final item in response.data!) {
      final raw = item as Map<String, dynamic>;
      final pair = raw['symbol'] as String;
      final resolved = pairsByAsset.values.firstWhere(
        (entry) => entry.exchangeSymbol == pair,
        orElse: () => const MarketPair(
            assetSymbol: '',
            exchangeSymbol: '',
            baseCurrency: '',
            quoteCurrency: QuoteCurrency.inr,
            source: 'Binance'),
      );
      if (resolved.assetSymbol.isNotEmpty) {
        result[resolved.assetSymbol] =
            _parseTicker(resolved.assetSymbol, resolved, raw);
      }
    }
    return result;
  }

  /// Returns OHLCV candles for [symbol] using the given [interval] and [limit].
  ///
  /// [interval] must be a valid Binance kline interval string
  /// (e.g. `'1m'`, `'5m'`, `'1h'`, `'1d'`).
  Future<List<MarketCandle>> getCandles(
    String symbol, {
    String interval = '1h',
    int limit = 100,
  }) async {
    final pair = await resolvePair(symbol);
    final response = await _dio.get<List<dynamic>>(
      '/api/v3/klines',
      queryParameters: {
        'symbol': pair.exchangeSymbol,
        'interval': interval,
        'limit': limit,
      },
    );

    return response.data!.map((raw) {
      final kline = raw as List<dynamic>;
      // Binance kline format:
      // [0] open time ms, [1] open, [2] high, [3] low, [4] close, [5] volume
      return MarketCandle(
        timestamp: DateTime.fromMillisecondsSinceEpoch(kline[0] as int),
        open: _toInr(double.parse(kline[1] as String), pair),
        high: _toInr(double.parse(kline[2] as String), pair),
        low: _toInr(double.parse(kline[3] as String), pair),
        close: _toInr(double.parse(kline[4] as String), pair),
        volume: double.parse(kline[5] as String),
      );
    }).toList();
  }

  /// Returns the list of [CryptoAsset] objects for all supported symbols.
  ///
  /// Fetches live tickers and constructs assets from them.  The [iconUrl]
  /// field points to the CoinGecko CDN by convention; the asset is otherwise
  /// self-contained.
  Future<List<CryptoAsset>> getSupportedAssets() async {
    final tickers = await getAllTickers();
    return CryptoAsset.supportedV1Symbols.map((symbol) {
      final ticker = tickers[symbol];
      final priceInr = ticker?.priceInr ?? 0.0;

      // 24h change percent derived from Binance's priceChangePercent field is
      // stored in the ticker's extra data map where available; otherwise 0.
      final change = _changeCache[symbol] ?? 0.0;

      return CryptoAsset(
        symbol: symbol,
        name: _assetNames[symbol] ?? symbol,
        iconUrl: _iconUrl(symbol),
        currentPriceInr: priceInr,
        change24hPercent: change,
        exchangeSymbol: ticker?.exchangeSymbol,
        quoteCurrency: ticker?.quoteCurrency,
        source: ticker?.source,
        priceTimestamp: ticker?.timestamp,
        freshness: ticker?.freshness ?? MarketFreshness.error,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Cached 24h change percent values keyed by canonical symbol.
  /// Populated as a side-effect of [getAllTickers] / [getTicker].
  final Map<String, double> _changeCache = {};

  static const Map<String, String> _assetNames = {
    'BTC': 'Bitcoin',
    'ETH': 'Ethereum',
    'SOL': 'Solana',
    'XRP': 'XRP',
    'BNB': 'BNB',
  };

  static String _iconUrl(String symbol) =>
      'https://assets.coingecko.com/coins/images/'
      '${_coinGeckoImageId[symbol] ?? symbol.toLowerCase()}/large/thumb.png';

  static const Map<String, String> _coinGeckoImageId = {
    'BTC': '1/bitcoin',
    'ETH': '279/ethereum',
    'SOL': '4128/solana',
    'XRP': '44/xrp',
    'BNB': '825/bnb',
  };

  Future<MarketPair> resolvePair(String symbol) async {
    final pair = (await resolveAllPairs())[symbol.toUpperCase()];
    if (pair == null) throw NoSupportedMarketPair(symbol.toUpperCase());
    return pair;
  }

  Future<Map<String, MarketPair>> resolveAllPairs() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/v3/exchangeInfo');
    final rawSymbols = response.data?['symbols'];
    if (rawSymbols is! List)
      throw const NoSupportedMarketPair('exchange metadata');
    final result = <String, MarketPair>{};
    for (final item in rawSymbols) {
      if (item is! Map<String, dynamic> || item['status'] != 'TRADING')
        continue;
      final base = item['baseAsset'] as String?;
      final quote = item['quoteAsset'] as String?;
      final exchangeSymbol = item['symbol'] as String?;
      if (base == null ||
          quote == null ||
          exchangeSymbol == null ||
          !_quotePriority.contains(quote)) continue;
      final candidate = MarketPair(
        assetSymbol: base,
        exchangeSymbol: exchangeSymbol,
        baseCurrency: base,
        quoteCurrency: QuoteCurrency.values.firstWhere(
            (currency) => currency.code == quote,
            orElse: () => QuoteCurrency.usdt),
        source: 'Binance',
      );
      final existing = result[base];
      result[base] =
          selectPreferredPair([if (existing != null) existing, candidate]) ??
              candidate;
    }
    return result;
  }

  double _toInr(double nativePrice, MarketPair pair) {
    if (pair.isInr) return nativePrice;
    final rate = _fxRateForQuote(pair.quoteCurrency.code);
    if (rate == null || !rate.isFinite || rate <= 0)
      throw ExchangeRateUnavailable(pair.quoteCurrency.code, 'INR');
    return nativePrice * rate;
  }

  MarketTicker _parseTicker(
      String symbol, MarketPair pair, Map<String, dynamic> raw) {
    final lastPrice = _toInr(double.parse(raw['lastPrice'] as String), pair);
    final high = _toInr(double.parse(raw['highPrice'] as String), pair);
    final low = _toInr(double.parse(raw['lowPrice'] as String), pair);
    final volume = double.parse(raw['volume'] as String);
    final changePercent =
        double.tryParse(raw['priceChangePercent'] as String) ?? 0.0;

    _changeCache[symbol] = changePercent;

    return MarketTicker(
      symbol: symbol,
      priceInr: lastPrice,
      high24h: high,
      low24h: low,
      volume24h: volume,
      timestamp: DateTime.now(),
      exchangeSymbol: pair.exchangeSymbol,
      quoteCurrency: pair.quoteCurrency.code,
      source: pair.source,
    );
  }
}
