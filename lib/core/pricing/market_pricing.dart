import 'package:flutter/foundation.dart';

/// Currencies used by market quotes and the application's account currency.
enum QuoteCurrency { inr, usd, usdt, usdc }

enum MarketFreshness { live, stale, offline, error }

extension QuoteCurrencyCode on QuoteCurrency {
  String get code => switch (this) {
        QuoteCurrency.inr => 'INR',
        QuoteCurrency.usd => 'USD',
        QuoteCurrency.usdt => 'USDT',
        QuoteCurrency.usdc => 'USDC',
      };
}

/// A validated exchange market.  Asset symbols and exchange pairs are
/// deliberately separate so UI navigation cannot accidentally send BTC where
/// an exchange expects BTCUSDT.
@immutable
class MarketPair {
  final String assetSymbol;
  final String exchangeSymbol;
  final String baseCurrency;
  final QuoteCurrency quoteCurrency;
  final String source;

  const MarketPair({
    required this.assetSymbol,
    required this.exchangeSymbol,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.source,
  });

  bool get isInr => quoteCurrency == QuoteCurrency.inr;

  @override
  bool operator ==(Object other) =>
      other is MarketPair &&
      assetSymbol == other.assetSymbol &&
      exchangeSymbol == other.exchangeSymbol &&
      quoteCurrency == other.quoteCurrency &&
      source == other.source;

  @override
  int get hashCode =>
      Object.hash(assetSymbol, exchangeSymbol, quoteCurrency, source);
}

@immutable
class NativeMarketPrice {
  final MarketPair pair;
  final double price;
  final DateTime timestamp;

  const NativeMarketPrice(
      {required this.pair, required this.price, required this.timestamp});

  bool get isValid => price.isFinite && price > 0;
}

@immutable
class ExchangeRate {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime timestamp;
  final String source;

  const ExchangeRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.timestamp,
    required this.source,
  });

  bool get isValid => rate.isFinite && rate > 0;
}

@immutable
class InrPrice {
  final String assetSymbol;
  final MarketPair pair;
  final double priceInr;
  final String? fxSource;
  final DateTime marketTimestamp;
  final DateTime? fxTimestamp;
  final DateTime calculatedAt;

  const InrPrice({
    required this.assetSymbol,
    required this.pair,
    required this.priceInr,
    required this.fxSource,
    required this.marketTimestamp,
    required this.fxTimestamp,
    required this.calculatedAt,
  });

  bool get isValid => priceInr.isFinite && priceInr > 0;
}

sealed class PricingFailure implements Exception {
  final String message;
  const PricingFailure(this.message);
  @override
  String toString() => message;
}

class NoSupportedMarketPair extends PricingFailure {
  const NoSupportedMarketPair(String asset)
      : super('No supported live market pair for $asset');
}

class InvalidMarketPrice extends PricingFailure {
  const InvalidMarketPrice(String pair)
      : super('Invalid live market price for $pair');
}

class ExchangeRateUnavailable extends PricingFailure {
  const ExchangeRateUnavailable(String from, String to)
      : super('Live exchange rate unavailable for $from/$to');
}

abstract interface class FxProvider {
  Future<ExchangeRate> getExchangeRate(String fromCurrency, String toCurrency);
}

abstract interface class MarketPairResolver {
  Future<MarketPair> resolve(String assetSymbol);
}

MarketPair? selectPreferredPair(Iterable<MarketPair> pairs) {
  const priority = [
    QuoteCurrency.inr,
    QuoteCurrency.usdt,
    QuoteCurrency.usdc,
    QuoteCurrency.usd
  ];
  for (final quote in priority) {
    for (final pair in pairs) {
      if (pair.quoteCurrency == quote) return pair;
    }
  }
  return null;
}
