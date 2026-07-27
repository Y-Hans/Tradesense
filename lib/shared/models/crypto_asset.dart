import 'package:flutter/foundation.dart';

@immutable
class CryptoAsset {
  final String symbol;
  final String name;
  final String iconUrl;
  final double currentPriceInr;
  final double change24hPercent;
  final bool isSupportedV1;

  const CryptoAsset({
    required this.symbol,
    required this.name,
    required this.iconUrl,
    required this.currentPriceInr,
    required this.change24hPercent,
    this.isSupportedV1 = true,
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
      };

  factory CryptoAsset.fromJson(Map<String, dynamic> json) => CryptoAsset(
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        iconUrl: json['icon_url'] as String? ?? '',
        currentPriceInr: (json['current_price_inr'] as num).toDouble(),
        change24hPercent: (json['change_24h_percent'] as num).toDouble(),
        isSupportedV1: json['is_supported_v1'] as bool? ?? true,
      );
}
