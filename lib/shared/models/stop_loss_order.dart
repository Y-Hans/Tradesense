import 'package:flutter/foundation.dart';

enum StopLossStatus { active, triggered, cancelled }

@immutable
class StopLossOrder {
  final String id;
  final String tradeId;
  final String userId;
  final String symbol;
  final double triggerPriceInr;
  final double quantity;
  final StopLossStatus status;
  final DateTime createdAt;

  const StopLossOrder({
    required this.id,
    required this.tradeId,
    required this.userId,
    required this.symbol,
    required this.triggerPriceInr,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'trade_id': tradeId,
        'user_id': userId,
        'symbol': symbol,
        'trigger_price_inr': triggerPriceInr,
        'quantity': quantity,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory StopLossOrder.fromJson(Map<String, dynamic> json) => StopLossOrder(
        id: json['id'] as String,
        tradeId: json['trade_id'] as String,
        userId: json['user_id'] as String,
        symbol: json['symbol'] as String,
        triggerPriceInr: (json['trigger_price_inr'] as num).toDouble(),
        quantity: (json['quantity'] as num).toDouble(),
        status: StopLossStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
