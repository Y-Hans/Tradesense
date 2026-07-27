import 'package:flutter/foundation.dart';

@immutable
class Holding {
  final String id;
  final String userId;
  final String symbol;
  final double quantity;
  final double averageEntryPriceInr;
  final double currentPriceInr;

  const Holding({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.quantity,
    required this.averageEntryPriceInr,
    required this.currentPriceInr,
  });

  double get totalCostInr => quantity * averageEntryPriceInr;
  double get currentValueInr => quantity * currentPriceInr;
  double get unrealisedPnlInr => currentValueInr - totalCostInr;
  double get unrealisedPnlPercent =>
      totalCostInr == 0 ? 0.0 : (unrealisedPnlInr / totalCostInr) * 100.0;

  Holding copyWith({
    String? id,
    String? userId,
    String? symbol,
    double? quantity,
    double? averageEntryPriceInr,
    double? currentPriceInr,
  }) {
    return Holding(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      averageEntryPriceInr: averageEntryPriceInr ?? this.averageEntryPriceInr,
      currentPriceInr: currentPriceInr ?? this.currentPriceInr,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'symbol': symbol,
        'quantity': quantity,
        'average_entry_price_inr': averageEntryPriceInr,
        'current_price_inr': currentPriceInr,
      };

  factory Holding.fromJson(Map<String, dynamic> json) => Holding(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        symbol: json['symbol'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        averageEntryPriceInr:
            (json['average_entry_price_inr'] as num).toDouble(),
        currentPriceInr: (json['current_price_inr'] as num).toDouble(),
      );
}
