import 'package:cryptoedu/core/pricing/currency_converter.dart';
import 'package:cryptoedu/core/pricing/market_pricing.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fx implements FxProvider {
  final ExchangeRate value;
  _Fx(this.value);
  @override
  Future<ExchangeRate> getExchangeRate(
          String fromCurrency, String toCurrency) async =>
      value;
}

void main() {
  test('market pair keeps asset and exchange symbol distinct', () {
    const pair = MarketPair(
      assetSymbol: 'BTC',
      exchangeSymbol: 'BTCUSDT',
      baseCurrency: 'BTC',
      quoteCurrency: QuoteCurrency.usdt,
      source: 'Binance',
    );
    expect(pair.assetSymbol, 'BTC');
    expect(pair.exchangeSymbol, 'BTCUSDT');
    expect(pair.isInr, isFalse);
  });

  test('pair selection prefers direct INR and then approved liquid quotes', () {
    const usdt = MarketPair(
        assetSymbol: 'BTC',
        exchangeSymbol: 'BTCUSDT',
        baseCurrency: 'BTC',
        quoteCurrency: QuoteCurrency.usdt,
        source: 'Binance');
    const inr = MarketPair(
        assetSymbol: 'BTC',
        exchangeSymbol: 'BTCINR',
        baseCurrency: 'BTC',
        quoteCurrency: QuoteCurrency.inr,
        source: 'Binance');
    expect(selectPreferredPair([usdt, inr])?.exchangeSymbol, 'BTCINR');
    expect(selectPreferredPair([usdt])?.quoteCurrency, QuoteCurrency.usdt);
  });

  test('currency converter applies live rate and zero default fee', () async {
    final conversion = await CurrencyConverter(
      fxProvider: _Fx(ExchangeRate(
        fromCurrency: 'USD',
        toCurrency: 'INR',
        rate: 83.25,
        timestamp: DateTime(2026, 8, 15),
        source: 'test',
      )),
    ).convert(amount: 100, fromCurrency: 'USD', toCurrency: 'INR');

    expect(conversion.grossAmount, 8325);
    expect(conversion.feeAmount, 0);
    expect(conversion.finalAmount, 8325);
  });

  test('invalid FX rate fails instead of falling back', () async {
    expect(
      () => CurrencyConverter(
        fxProvider: _Fx(ExchangeRate(
          fromCurrency: 'USD',
          toCurrency: 'INR',
          rate: double.nan,
          timestamp: DateTime.now(),
          source: 'test',
        )),
      ).convert(amount: 1, fromCurrency: 'USD', toCurrency: 'INR'),
      throwsA(isA<ExchangeRateUnavailable>()),
    );
  });
}
