import 'package:flutter/foundation.dart';
import '../../core/pricing/market_pricing.dart';

@immutable
class CryptoAsset {
  final String symbol;
  final String name;
  final String iconUrl;
  final double currentPriceInr;
  final double change24hPercent;
  final bool isSupportedV1;
  final String? exchangeSymbol;
  final String? quoteCurrency;
  final String? source;
  final DateTime? priceTimestamp;
  final MarketFreshness freshness;

  const CryptoAsset({
    required this.symbol,
    required this.name,
    required this.iconUrl,
    required this.currentPriceInr,
    required this.change24hPercent,
    this.isSupportedV1 = true,
    this.exchangeSymbol,
    this.quoteCurrency,
    this.source,
    this.priceTimestamp,
    this.freshness = MarketFreshness.live,
  });

  static const List<String> supportedV1Symbols = [
    'BTC',
    'ETH',
    'SOL',
    'XRP',
    'BNB'
  ];

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'name': name,
        'icon_url': iconUrl,
        'current_price_inr': currentPriceInr,
        'change_24h_percent': change24hPercent,
        'is_supported_v1': isSupportedV1,
        'exchange_symbol': exchangeSymbol,
        'quote_currency': quoteCurrency,
        'source': source,
        'price_timestamp': priceTimestamp?.toIso8601String(),
        'freshness': freshness.name,
      };

  factory CryptoAsset.fromJson(Map<String, dynamic> json) => CryptoAsset(
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        iconUrl: json['icon_url'] as String? ?? '',
        currentPriceInr: (json['current_price_inr'] as num).toDouble(),
        change24hPercent: (json['change_24h_percent'] as num).toDouble(),
        isSupportedV1: json['is_supported_v1'] as bool? ?? true,
        exchangeSymbol: json['exchange_symbol'] as String?,
        quoteCurrency: json['quote_currency'] as String?,
        source: json['source'] as String?,
        priceTimestamp: json['price_timestamp'] == null
            ? null
            : DateTime.parse(json['price_timestamp'] as String),
        freshness: MarketFreshness.values.firstWhere(
            (value) => value.name == json['freshness'],
            orElse: () => MarketFreshness.live),
      );
}
