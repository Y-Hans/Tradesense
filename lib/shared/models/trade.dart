import 'package:flutter/foundation.dart';

enum TradeSide { buy, sell }

enum OrderType { market, stopLoss }

@immutable
class Trade {
  final String id;
  final String userId;
  final String symbol;
  final TradeSide side;
  final OrderType type;
  final double quantity;
  final double executionPriceInr;
  final double totalAmountInr;
  final double? stopLossPriceInr;
  final DateTime timestamp;
  final int disciplineScoreAtTrade;
  final int riskScoreAtTrade;
  final double? realizedPnl;

  const Trade({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.side,
    required this.type,
    required this.quantity,
    required this.executionPriceInr,
    required this.totalAmountInr,
    this.stopLossPriceInr,
    required this.timestamp,
    required this.disciplineScoreAtTrade,
    required this.riskScoreAtTrade,
    this.realizedPnl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'symbol': symbol,
        'side': side.name,
        'type': type.name,
        'quantity': quantity,
        'execution_price_inr': executionPriceInr,
        'total_amount_inr': totalAmountInr,
        'stop_loss_price_inr': stopLossPriceInr,
        'timestamp': timestamp.toIso8601String(),
        'discipline_score_at_trade': disciplineScoreAtTrade,
        'risk_score_at_trade': riskScoreAtTrade,
        'realized_pnl': realizedPnl,
      };

  factory Trade.fromJson(Map<String, dynamic> json) => Trade(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        symbol: json['symbol'] as String,
        side: TradeSide.values.byName(json['side'] as String),
        type: OrderType.values.byName(json['type'] as String),
        quantity: (json['quantity'] as num).toDouble(),
        executionPriceInr: (json['execution_price_inr'] as num).toDouble(),
        totalAmountInr: (json['total_amount_inr'] as num).toDouble(),
        stopLossPriceInr: json['stop_loss_price_inr'] != null
            ? (json['stop_loss_price_inr'] as num).toDouble()
            : null,
        timestamp: DateTime.parse(json['timestamp'] as String),
        disciplineScoreAtTrade:
            (json['discipline_score_at_trade'] as num).toInt(),
        riskScoreAtTrade: (json['risk_score_at_trade'] as num).toInt(),
        realizedPnl: json['realized_pnl'] != null
            ? (json['realized_pnl'] as num).toDouble()
            : null,
      );
}
