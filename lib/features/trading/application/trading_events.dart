import 'package:flutter/foundation.dart';

import '../../../shared/models/trade.dart';

@immutable
sealed class TradingEvent {
  final String userId;
  final DateTime occurredAt;

  const TradingEvent({
    required this.userId,
    required this.occurredAt,
  });

  String get eventName;
  Map<String, Object?> get payload;
}

@immutable
class FirstTradeCompleted extends TradingEvent {
  final String tradeId;
  final String assetSymbol;
  final TradeSide side;
  final double totalAmountInr;

  const FirstTradeCompleted({
    required super.userId,
    required super.occurredAt,
    required this.tradeId,
    required this.assetSymbol,
    required this.side,
    required this.totalAmountInr,
  });

  @override
  String get eventName => 'FirstTradeCompleted';

  @override
  Map<String, Object?> get payload => {
        'tradeId': tradeId,
        'assetSymbol': assetSymbol,
        'side': side.name,
        'totalAmountInr': totalAmountInr,
      };
}

@immutable
class FirstProfitableTradeCompleted extends TradingEvent {
  final String tradeId;
  final String assetSymbol;
  final double realizedProfitLossInr;

  const FirstProfitableTradeCompleted({
    required super.userId,
    required super.occurredAt,
    required this.tradeId,
    required this.assetSymbol,
    required this.realizedProfitLossInr,
  });

  @override
  String get eventName => 'FirstProfitableTradeCompleted';

  @override
  Map<String, Object?> get payload => {
        'tradeId': tradeId,
        'assetSymbol': assetSymbol,
        'realizedProfitLossInr': realizedProfitLossInr,
      };
}

@immutable
class FirstLosingTradeCompleted extends TradingEvent {
  final String tradeId;
  final String assetSymbol;
  final double realizedProfitLossInr;

  const FirstLosingTradeCompleted({
    required super.userId,
    required super.occurredAt,
    required this.tradeId,
    required this.assetSymbol,
    required this.realizedProfitLossInr,
  });

  @override
  String get eventName => 'FirstLosingTradeCompleted';

  @override
  Map<String, Object?> get payload => {
        'tradeId': tradeId,
        'assetSymbol': assetSymbol,
        'realizedProfitLossInr': realizedProfitLossInr,
      };
}

@immutable
class PortfolioViewed extends TradingEvent {
  final double portfolioValueInr;
  final int numberOfAssets;
  final int numberOfOpenHoldings;

  const PortfolioViewed({
    required super.userId,
    required super.occurredAt,
    required this.portfolioValueInr,
    required this.numberOfAssets,
    required this.numberOfOpenHoldings,
  });

  @override
  String get eventName => 'PortfolioViewed';

  @override
  Map<String, Object?> get payload => {
        'portfolioValueInr': portfolioValueInr,
        'numberOfAssets': numberOfAssets,
        'numberOfOpenHoldings': numberOfOpenHoldings,
      };
}

@immutable
class TradeHistoryViewed extends TradingEvent {
  final int totalTrades;
  final int profitableTrades;
  final int losingTrades;

  const TradeHistoryViewed({
    required super.userId,
    required super.occurredAt,
    required this.totalTrades,
    required this.profitableTrades,
    required this.losingTrades,
  });

  @override
  String get eventName => 'TradeHistoryViewed';

  @override
  Map<String, Object?> get payload => {
        'totalTrades': totalTrades,
        'profitableTrades': profitableTrades,
        'losingTrades': losingTrades,
      };
}

@immutable
class FiveTradesCompleted extends TradingEvent {
  const FiveTradesCompleted({
    required super.userId,
    required super.occurredAt,
  });

  @override
  String get eventName => 'FiveTradesCompleted';

  @override
  Map<String, Object?> get payload => const {'totalTrades': 5};
}

@immutable
class TenTradesCompleted extends TradingEvent {
  const TenTradesCompleted({
    required super.userId,
    required super.occurredAt,
  });

  @override
  String get eventName => 'TenTradesCompleted';

  @override
  Map<String, Object?> get payload => const {'totalTrades': 10};
}

@immutable
class StopLossTriggered extends TradingEvent {
  final String stopLossOrderId;
  final String assetSymbol;
  final double quantity;
  final double marketPriceInr;
  final double triggerPriceInr;

  const StopLossTriggered({
    required super.userId,
    required super.occurredAt,
    required this.stopLossOrderId,
    required this.assetSymbol,
    required this.quantity,
    required this.marketPriceInr,
    required this.triggerPriceInr,
  });

  @override
  String get eventName => 'StopLossTriggered';

  @override
  Map<String, Object?> get payload => {
        'stopLossOrderId': stopLossOrderId,
        'assetSymbol': assetSymbol,
        'quantity': quantity,
        'marketPriceInr': marketPriceInr,
        'triggerPriceInr': triggerPriceInr,
      };
}

@immutable
class AutomaticSellExecuted extends TradingEvent {
  final String stopLossOrderId;
  final String tradeId;
  final String assetSymbol;
  final double quantity;
  final double proceedsInr;
  final double realizedProfitLossInr;

  const AutomaticSellExecuted({
    required super.userId,
    required super.occurredAt,
    required this.stopLossOrderId,
    required this.tradeId,
    required this.assetSymbol,
    required this.quantity,
    required this.proceedsInr,
    required this.realizedProfitLossInr,
  });

  @override
  String get eventName => 'AutomaticSellExecuted';

  @override
  Map<String, Object?> get payload => {
        'stopLossOrderId': stopLossOrderId,
        'tradeId': tradeId,
        'assetSymbol': assetSymbol,
        'quantity': quantity,
        'proceedsInr': proceedsInr,
        'realizedProfitLossInr': realizedProfitLossInr,
      };
}
