import 'package:flutter/foundation.dart';
import '../../core/pricing/market_pricing.dart';

@immutable
class MarketTicker {
  final String symbol;
  final double priceInr;
  final double high24h;
  final double low24h;
  final double volume24h;
  final DateTime timestamp;
  final String? exchangeSymbol;
  final String? quoteCurrency;
  final String? source;
  final MarketFreshness freshness;

  const MarketTicker({
    required this.symbol,
    required this.priceInr,
    required this.high24h,
    required this.low24h,
    required this.volume24h,
    required this.timestamp,
    this.exchangeSymbol,
    this.quoteCurrency,
    this.source,
    this.freshness = MarketFreshness.live,
  });

  bool get isStale =>
      freshness == MarketFreshness.stale ||
      DateTime.now().difference(timestamp).inSeconds > 30;

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'price_inr': priceInr,
        'high_24h': high24h,
        'low_24h': low24h,
        'volume_24h': volume24h,
        'timestamp': timestamp.toIso8601String(),
        'exchange_symbol': exchangeSymbol,
        'quote_currency': quoteCurrency,
        'source': source,
        'freshness': freshness.name,
      };

  factory MarketTicker.fromJson(Map<String, dynamic> json) => MarketTicker(
        symbol: json['symbol'] as String,
        priceInr: (json['price_inr'] as num).toDouble(),
        high24h: (json['high_24h'] as num).toDouble(),
        low24h: (json['low_24h'] as num).toDouble(),
        volume24h: (json['volume_24h'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        exchangeSymbol: json['exchange_symbol'] as String?,
        quoteCurrency: json['quote_currency'] as String?,
        source: json['source'] as String?,
        freshness: MarketFreshness.values.firstWhere(
          (value) => value.name == json['freshness'],
          orElse: () => MarketFreshness.live,
        ),
      );

  MarketTicker copyWith({MarketFreshness? freshness}) => MarketTicker(
        symbol: symbol,
        priceInr: priceInr,
        high24h: high24h,
        low24h: low24h,
        volume24h: volume24h,
        timestamp: timestamp,
        exchangeSymbol: exchangeSymbol,
        quoteCurrency: quoteCurrency,
        source: source,
        freshness: freshness ?? this.freshness,
      );
}

@immutable
class MarketCandle {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const MarketCandle({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'volume': volume,
      };

  factory MarketCandle.fromJson(Map<String, dynamic> json) => MarketCandle(
        timestamp: DateTime.parse(json['timestamp'] as String),
        open: (json['open'] as num).toDouble(),
        high: (json['high'] as num).toDouble(),
        low: (json['low'] as num).toDouble(),
        close: (json['close'] as num).toDouble(),
        volume: (json['volume'] as num).toDouble(),
      );
}
