import 'package:dio/dio.dart';
import '../../../shared/models/crypto_asset.dart';
import '../../../shared/models/market_ticker.dart';

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
/// Binance quotes prices in USDT.  This client converts to INR using the
/// [usdToInrRate] parameter which callers must supply (e.g. sourced from a
/// separate forex endpoint or [CoinGeckoClient]).
///
/// ## Usage
/// Obtain an instance through the Riverpod provider rather than constructing
/// directly — see `market_api_provider.dart`.
class BinanceRestClient {
  BinanceRestClient({
    required Dio dio,
    required double Function() usdToInrRate,
  })  : _dio = dio,
        _usdToInrRate = usdToInrRate;

  final Dio _dio;
  final double Function() _usdToInrRate;

  // ---------------------------------------------------------------------------
  // Supported symbols — Binance uses USDT pairs
  // ---------------------------------------------------------------------------

  /// Maps our canonical symbol (e.g. `'BTC'`) to its Binance trading pair
  /// (e.g. `'BTCUSDT'`).
  static const Map<String, String> _pairMap = {
    'BTC': 'BTCUSDT',
    'ETH': 'ETHUSDT',
    'SOL': 'SOLUSDT',
    'XRP': 'XRPUSDT',
    'BNB': 'BNBUSDT',
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns a [MarketTicker] for [symbol] (e.g. `'BTC'`).
  ///
  /// Fetches 24-hour statistics from Binance and converts the USDT price to
  /// INR using the stored [_usdToInrRate].
  ///
  /// Throws [ArgumentError] if [symbol] is not in the supported set.
  /// Throws [DioException] on network failure (after retries).
  Future<MarketTicker> getTicker(String symbol) async {
    final pair = _requirePair(symbol);
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v3/ticker/24hr',
      queryParameters: {'symbol': pair},
    );
    return _parseTicker(symbol, response.data!);
  }

  /// Returns 24-hour statistics for all supported symbols in one batch call.
  ///
  /// Uses the array-form of `/api/v3/ticker/24hr` so that a single round-trip
  /// fetches all pairs.
  Future<Map<String, MarketTicker>> getAllTickers() async {
    final pairs = _pairMap.values.toList();
    final symbols = '[${pairs.map((p) => '"$p"').join(',')}]';

    final response = await _dio.get<List<dynamic>>(
      '/api/v3/ticker/24hr',
      queryParameters: {'symbols': symbols},
    );

    final result = <String, MarketTicker>{};
    for (final item in response.data!) {
      final raw = item as Map<String, dynamic>;
      final pair = raw['symbol'] as String;
      final canonical = _pairMap.entries
          .firstWhere((e) => e.value == pair,
              orElse: () => const MapEntry('', ''))
          .key;
      if (canonical.isNotEmpty) {
        result[canonical] = _parseTicker(canonical, raw);
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
    final pair = _requirePair(symbol);
    final response = await _dio.get<List<dynamic>>(
      '/api/v3/klines',
      queryParameters: {
        'symbol': pair,
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
        open: double.parse(kline[1] as String) * _usdToInrRate(),
        high: double.parse(kline[2] as String) * _usdToInrRate(),
        low: double.parse(kline[3] as String) * _usdToInrRate(),
        close: double.parse(kline[4] as String) * _usdToInrRate(),
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

  String _requirePair(String symbol) {
    final pair = _pairMap[symbol.toUpperCase()];
    if (pair == null) {
      throw ArgumentError(
          'Symbol "$symbol" is not in the supported Binance pair map.');
    }
    return pair;
  }

  MarketTicker _parseTicker(String symbol, Map<String, dynamic> raw) {
    final rate = _usdToInrRate();
    final lastPrice = double.parse(raw['lastPrice'] as String) * rate;
    final high = double.parse(raw['highPrice'] as String) * rate;
    final low = double.parse(raw['lowPrice'] as String) * rate;
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
    );
  }
}
