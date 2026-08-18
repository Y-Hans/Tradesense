import 'package:dio/dio.dart';
import 'market_pricing.dart';

/// Public, keyless FX provider used for display conversion. Execution uses the
/// same source policy in the Edge Function and never falls back to a cached or
/// hardcoded rate.
class PublicFxProvider implements FxProvider {
  final Dio _usdDio;
  final Dio _coinGeckoDio;

  const PublicFxProvider({required Dio usdDio, required Dio coinGeckoDio})
      : _usdDio = usdDio,
        _coinGeckoDio = coinGeckoDio;

  @override
  Future<ExchangeRate> getExchangeRate(
      String fromCurrency, String toCurrency) async {
    final from = fromCurrency.toUpperCase();
    final to = toCurrency.toUpperCase();
    if (from == to) {
      return ExchangeRate(
          fromCurrency: from,
          toCurrency: to,
          rate: 1,
          timestamp: DateTime.now(),
          source: 'identity');
    }
    if (from == 'INR' && const ['USD', 'USDT', 'USDC'].contains(to)) {
      final inverse = await getExchangeRate(to, 'INR');
      return ExchangeRate(
        fromCurrency: from,
        toCurrency: to,
        rate: 1 / inverse.rate,
        timestamp: inverse.timestamp,
        source: inverse.source,
      );
    }
    if (to != 'INR') throw ExchangeRateUnavailable(from, to);

    final response = from == 'USD'
        ? await _usdDio.get<Map<String, dynamic>>('/latest',
            queryParameters: {'from': 'USD', 'to': 'INR'})
        : await _coinGeckoDio.get<Map<String, dynamic>>(
            '/simple/price',
            queryParameters: {
              'ids': from == 'USDT' ? 'tether' : 'usd-coin',
              'vs_currencies': 'inr'
            },
          );
    final raw = from == 'USD'
        ? response.data?['rates']?['INR']
        : response.data?[from == 'USDT' ? 'tether' : 'usd-coin']?['inr'];
    final rate = raw is num ? raw.toDouble() : double.nan;
    if (!rate.isFinite || rate <= 0) throw ExchangeRateUnavailable(from, to);
    return ExchangeRate(
      fromCurrency: from,
      toCurrency: to,
      rate: rate,
      timestamp: DateTime.now(),
      source: from == 'USD' ? 'Frankfurter' : 'CoinGecko',
    );
  }
}
