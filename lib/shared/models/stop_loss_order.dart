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
  final DateTime? expiresAt;
  final DateTime? triggeredAt;

  const StopLossOrder({
    required this.id,
    required this.tradeId,
    required this.userId,
    required this.symbol,
    required this.triggerPriceInr,
    required this.quantity,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.triggeredAt,
  });

  StopLossOrder copyWith({
    String? id,
    String? tradeId,
    String? userId,
    String? symbol,
    double? triggerPriceInr,
    double? quantity,
    StopLossStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? triggeredAt,
  }) {
    return StopLossOrder(
      id: id ?? this.id,
      tradeId: tradeId ?? this.tradeId,
      userId: userId ?? this.userId,
      symbol: symbol ?? this.symbol,
      triggerPriceInr: triggerPriceInr ?? this.triggerPriceInr,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trade_id': tradeId,
        'user_id': userId,
        'symbol': symbol,
        'trigger_price_inr': triggerPriceInr,
        'quantity': quantity,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'triggered_at': triggeredAt?.toIso8601String(),
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
        expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
        triggeredAt: json['triggered_at'] != null ? DateTime.parse(json['triggered_at'] as String) : null,
      );
}
