import 'dart:async';
import '../contracts/market_provider.dart';
import '../../shared/models/crypto_asset.dart';
import '../../shared/models/market_ticker.dart';
import 'binance/binance_rest_client.dart';
import 'binance/binance_ws_client.dart';
import 'coingecko/coingecko_client.dart';

/// Live [MarketProvider] implementation backed by Binance REST + WebSocket
/// with CoinGecko as a fallback.
///
/// ## Fallback strategy
/// 1. All REST calls attempt Binance first.
/// 2. On [DioException] (network error, timeout, rate-limit) the call is
///    transparently retried against [CoinGeckoClient].
/// 3. [streamTicker] always uses the Binance WebSocket; there is no streaming
///    fallback (callers can poll [getTicker] on error if needed).
///
/// ## INR conversion
/// [CoinGeckoClient.fetchUsdToInrRate] is called once at construction time
/// and cached.  The rate is refreshed every [_rateRefreshInterval] via an
/// internal timer so that long-running sessions stay accurate.
///
/// ## Usage
/// Obtain an instance through [marketApiProvider] — do NOT construct
/// directly outside of tests.
class BinanceMarketProvider implements MarketProvider {
  BinanceMarketProvider({
    required BinanceRestClient binanceRest,
    required BinanceWebSocketClient binanceWs,
    required CoinGeckoClient coinGecko,
    required double initialUsdToInrRate,
  })  : _binanceRest = binanceRest,
        _binanceWs = binanceWs,
        _coinGecko = coinGecko,
        _usdToInrRate = initialUsdToInrRate;

  final BinanceRestClient _binanceRest;
  final BinanceWebSocketClient _binanceWs;
  final CoinGeckoClient _coinGecko;

  double _usdToInrRate;
  double get usdToInrRate => _usdToInrRate;
  Timer? _rateRefreshTimer;

  static const Duration _rateRefreshInterval = Duration(minutes: 15);

  // ---------------------------------------------------------------------------
  // Rate refresh
  // ---------------------------------------------------------------------------

  /// Starts the periodic USD→INR rate refresh timer.
  ///
  /// Call this once after construction.  The provider factory in
  /// `market_api_provider.dart` handles this.
  void startRateRefresh() {
    _rateRefreshTimer = Timer.periodic(_rateRefreshInterval, (_) async {
      try {
        _usdToInrRate = await _coinGecko.fetchUsdToInrRate();
      } catch (_) {
        // Retain the last known rate on failure; do not crash.
      }
    });
  }

  /// Cancels the rate refresh timer and disposes the WebSocket client.
  Future<void> dispose() async {
    _rateRefreshTimer?.cancel();
    _rateRefreshTimer = null;
    await _binanceWs.dispose();
  }

  // ---------------------------------------------------------------------------
  // MarketProvider interface
  // ---------------------------------------------------------------------------

  @override
  Future<List<CryptoAsset>> getSupportedAssets() async {
    try {
      return await _binanceRest.getSupportedAssets();
    } catch (_) {
      return _coinGecko.getSupportedAssets();
    }
  }

  @override
  Future<MarketTicker> getTicker(String symbol) async {
    try {
      return await _binanceRest.getTicker(symbol);
    } catch (_) {
      return _coinGecko.getTicker(symbol);
    }
  }

  @override
  Future<Map<String, MarketTicker>> getAllTickers() async {
    try {
      return await _binanceRest.getAllTickers();
    } catch (_) {
      return _coinGecko.getAllTickers();
    }
  }

  @override
  Future<List<MarketCandle>> getCandles(
    String symbol, {
    String interval = '1h',
    int limit = 100,
  }) async {
    try {
      return await _binanceRest.getCandles(symbol,
          interval: interval, limit: limit);
    } catch (_) {
      // CoinGecko uses `days` rather than interval + limit.
      // Map common intervals to an approximate day count.
      final days = _intervalToDays(interval, limit);
      return _coinGecko.getCandles(symbol, days: days);
    }
  }

  @override
  Stream<MarketTicker> streamTicker(String symbol) {
    return _binanceWs.streamTicker(symbol);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Approximates a CoinGecko `days` value from a Binance kline interval +
  /// limit pair.
  static int _intervalToDays(String interval, int limit) {
    const minutesMap = {
      '1m': 1,
      '3m': 3,
      '5m': 5,
      '15m': 15,
      '30m': 30,
      '1h': 60,
      '2h': 120,
      '4h': 240,
      '6h': 360,
      '8h': 480,
      '12h': 720,
      '1d': 1440,
      '3d': 4320,
      '1w': 10080,
    };
    final minutesPerCandle = minutesMap[interval] ?? 60;
    final totalMinutes = minutesPerCandle * limit;
    final days = (totalMinutes / 1440).ceil();
    // CoinGecko accepts 1, 7, 14, 30, 90, 180, 365.
    const allowed = [1, 7, 14, 30, 90, 180, 365];
    return allowed.firstWhere((d) => d >= days, orElse: () => 365);
  }
}
