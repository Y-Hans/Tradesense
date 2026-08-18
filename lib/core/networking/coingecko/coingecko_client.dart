import 'package:dio/dio.dart';
import '../../../shared/models/crypto_asset.dart';
import '../../../shared/models/market_ticker.dart';

/// CoinGecko public REST API client.
///
/// Used as a fallback when the Binance REST client is unavailable or rate-
/// limited.  Also serves as the canonical source of the USD→INR conversion
/// rate used by both [BinanceRestClient] and [BinanceWebSocketClient].
///
/// ## Endpoints used
/// - `GET /simple/price` — spot prices + 24h change for multiple ids
/// - `GET /coins/markets` — full asset list with metadata
/// - `GET /coins/{id}/ohlc` — OHLCV candles for a single coin
///
/// ## Rate limits
/// The CoinGecko free tier allows ~10–30 requests/minute.  Callers must
/// cache aggressively and avoid polling this client on short intervals.
///
/// ## Usage
/// Obtain an instance through the Riverpod provider rather than constructing
/// directly — see `market_api_provider.dart`.
class CoinGeckoClient {
  CoinGeckoClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ---------------------------------------------------------------------------
  // Symbol → CoinGecko coin-id mapping
  // ---------------------------------------------------------------------------

  static const Map<String, String> _coinIds = {
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'SOL': 'solana',
    'XRP': 'ripple',
    'BNB': 'binancecoin',
  };

  // ---------------------------------------------------------------------------
  // USD → INR rate
  // ---------------------------------------------------------------------------

  /// Fetches the current USD → INR exchange rate from CoinGecko's VS-currency
  /// endpoint using Tether (USDT) as a stable USD proxy.
  ///
  /// Returns the number of INR per 1 USD.
  ///
  /// Throws when a live rate cannot be obtained. Execution paths must never
  /// guess an FX rate.
  Future<double> fetchUsdToInrRate() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/simple/price',
        queryParameters: {
          'ids': 'tether',
          'vs_currencies': 'inr',
        },
      );
      final inrPerUsdt = (response.data?['tether']?['inr'] as num?)?.toDouble();
      if (inrPerUsdt == null || !inrPerUsdt.isFinite || inrPerUsdt <= 0) {
        throw StateError('CoinGecko returned an invalid USD/INR rate.');
      }
      return inrPerUsdt;
    } on DioException catch (_) {
      throw StateError('Live USD/INR rate unavailable.');
    }
  }

  // ---------------------------------------------------------------------------
  // Market data
  // ---------------------------------------------------------------------------

  /// Returns a [MarketTicker] for [symbol] (e.g. `'BTC'`).
  ///
  /// Prices are returned in INR (`vs_currency=inr`).
  Future<MarketTicker> getTicker(String symbol) async {
    final id = _requireId(symbol);
    final response = await _dio.get<Map<String, dynamic>>(
      '/simple/price',
      queryParameters: {
        'ids': id,
        'vs_currencies': 'inr',
        'include_24hr_high': true,
        'include_24hr_low': true,
        'include_24hr_vol': true,
      },
    );

    final data = response.data?[id] as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('CoinGecko returned no data for coin "$id".');
    }

    return MarketTicker(
      symbol: symbol.toUpperCase(),
      priceInr: (data['inr'] as num).toDouble(),
      high24h: (data['inr_24h_high'] as num?)?.toDouble() ??
          (data['inr'] as num).toDouble(),
      low24h: (data['inr_24h_low'] as num?)?.toDouble() ??
          (data['inr'] as num).toDouble(),
      volume24h: (data['inr_24h_vol'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.now(),
      exchangeSymbol: '${symbol.toUpperCase()}INR',
      quoteCurrency: 'INR',
      source: 'CoinGecko',
    );
  }

  /// Returns [MarketTicker] values for all supported symbols in a single
  /// request.
  Future<Map<String, MarketTicker>> getAllTickers() async {
    final ids = _coinIds.values.join(',');
    final response = await _dio.get<Map<String, dynamic>>(
      '/simple/price',
      queryParameters: {
        'ids': ids,
        'vs_currencies': 'inr',
        'include_24hr_high': true,
        'include_24hr_low': true,
        'include_24hr_vol': true,
        'include_24hr_change': true,
      },
    );

    final result = <String, MarketTicker>{};
    for (final entry in _coinIds.entries) {
      final symbol = entry.key;
      final id = entry.value;
      final data = response.data?[id] as Map<String, dynamic>?;
      if (data == null) continue;

      result[symbol] = MarketTicker(
        symbol: symbol,
        priceInr: (data['inr'] as num).toDouble(),
        high24h: (data['inr_24h_high'] as num?)?.toDouble() ??
            (data['inr'] as num).toDouble(),
        low24h: (data['inr_24h_low'] as num?)?.toDouble() ??
            (data['inr'] as num).toDouble(),
        volume24h: (data['inr_24h_vol'] as num?)?.toDouble() ?? 0.0,
        timestamp: DateTime.now(),
        exchangeSymbol: '${symbol}INR',
        quoteCurrency: 'INR',
        source: 'CoinGecko',
      );
    }
    return result;
  }

  /// Returns [CryptoAsset] objects for all supported V1 symbols.
  ///
  /// Uses the `/coins/markets` endpoint to get rich metadata including image
  /// URLs and 24h change percentage in a single call.
  Future<List<CryptoAsset>> getSupportedAssets() async {
    final ids = _coinIds.values.join(',');
    final response = await _dio.get<List<dynamic>>(
      '/coins/markets',
      queryParameters: {
        'vs_currency': 'inr',
        'ids': ids,
        'order': 'market_cap_desc',
        'per_page': _coinIds.length,
        'page': 1,
        'sparkline': false,
        'price_change_percentage': '24h',
      },
    );

    final result = <CryptoAsset>[];
    for (final item in response.data!) {
      final raw = item as Map<String, dynamic>;
      final id = raw['id'] as String;
      final symbol = _coinIds.entries
          .firstWhere((e) => e.value == id,
              orElse: () => const MapEntry('', ''))
          .key;
      if (symbol.isEmpty) continue;

      result.add(CryptoAsset(
        symbol: symbol,
        name: raw['name'] as String,
        iconUrl: raw['image'] as String? ?? '',
        currentPriceInr: (raw['current_price'] as num?)?.toDouble() ?? 0.0,
        change24hPercent:
            (raw['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
        exchangeSymbol: '${symbol}INR',
        quoteCurrency: 'INR',
        source: 'CoinGecko',
        priceTimestamp: DateTime.now(),
      ));
    }
    return result;
  }

  /// Returns OHLCV candles for [symbol] using the CoinGecko `/coins/{id}/ohlc`
  /// endpoint.
  ///
  /// [days] must be one of `1`, `7`, `14`, `30`, `90`, `180`, `365`.
  /// Candle prices are returned in INR.
  Future<List<MarketCandle>> getCandles(
    String symbol, {
    int days = 1,
  }) async {
    final id = _requireId(symbol);
    final response = await _dio.get<List<dynamic>>(
      '/coins/$id/ohlc',
      queryParameters: {
        'vs_currency': 'inr',
        'days': days,
      },
    );

    return response.data!.map((raw) {
      // CoinGecko OHLC format: [timestamp_ms, open, high, low, close]
      final row = raw as List<dynamic>;
      return MarketCandle(
        timestamp: DateTime.fromMillisecondsSinceEpoch(row[0] as int),
        open: (row[1] as num).toDouble(),
        high: (row[2] as num).toDouble(),
        low: (row[3] as num).toDouble(),
        close: (row[4] as num).toDouble(),
        volume: 0.0, // CoinGecko OHLC endpoint does not include volume.
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  String _requireId(String symbol) {
    final id = _coinIds[symbol.toUpperCase()];
    if (id == null) {
      throw ArgumentError(
          'Symbol "$symbol" is not in the supported CoinGecko id map.');
    }
    return id;
  }
}
