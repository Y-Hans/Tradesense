import 'package:flutter/foundation.dart';

import '../../../shared/models/trade.dart';
import 'trading_failure.dart';

sealed class TradeHistoryResult {
  const TradeHistoryResult();

  bool get isSuccess => this is TradeHistorySuccess;
  bool get isFailure => this is TradeHistoryRejected;
}

@immutable
class TradeHistorySuccess extends TradeHistoryResult {
  final TradeHistorySnapshot snapshot;

  const TradeHistorySuccess({
    required this.snapshot,
  });
}

@immutable
class TradeHistoryRejected extends TradeHistoryResult {
  final TradingFailure failure;

  const TradeHistoryRejected(this.failure);
}

@immutable
class TradeHistorySnapshot {
  final List<TradeTimelineEntry> timeline;
  final List<AssetTradeAnalytics> assetAnalytics;
  final TradeHistoryStatistics statistics;
  final TradeHistorySummary summary;
  final TradeHistoryReplay replay;
  final DateTime evaluatedAt;

  const TradeHistorySnapshot({
    required this.timeline,
    required this.assetAnalytics,
    required this.statistics,
    required this.summary,
    required this.replay,
    required this.evaluatedAt,
  });
}

@immutable
class TradeTimelineEntry {
  final Trade trade;
  final String assetSymbol;
  final TradeSide side;
  final DateTime executionTime;
  final double quantity;
  final double executionPriceInr;
  final double totalValueInr;
  final double realizedProfitLossInr;
  final double runningCumulativeCashFlowInr;
  final double runningRealizedProfitLossInr;

  const TradeTimelineEntry({
    required this.trade,
    required this.assetSymbol,
    required this.side,
    required this.executionTime,
    required this.quantity,
    required this.executionPriceInr,
    required this.totalValueInr,
    required this.realizedProfitLossInr,
    required this.runningCumulativeCashFlowInr,
    required this.runningRealizedProfitLossInr,
  });
}

@immutable
class AssetTradeAnalytics {
  final String assetSymbol;
  final int tradeCount;
  final int buyCount;
  final int sellCount;
  final double realizedProfitInr;
  final double realizedLossInr;
  final double netRealizedProfitLossInr;
  final double averageBuyPriceInr;
  final double averageSellPriceInr;
  final TradeTimelineEntry? largestTrade;
  final DateTime? lastTradeTime;

  const AssetTradeAnalytics({
    required this.assetSymbol,
    required this.tradeCount,
    required this.buyCount,
    required this.sellCount,
    required this.realizedProfitInr,
    required this.realizedLossInr,
    required this.netRealizedProfitLossInr,
    required this.averageBuyPriceInr,
    required this.averageSellPriceInr,
    required this.largestTrade,
    required this.lastTradeTime,
  });
}

@immutable
class TradeHistoryStatistics {
  final int totalTrades;
  final int totalBuyTrades;
  final int totalSellTrades;
  final double winRate;
  final double lossRate;
  final double breakEvenRate;
  final double largestGainInr;
  final double largestLossInr;
  final double averageGainInr;
  final double averageLossInr;
  final double profitFactor;
  final double netRealizedProfitLossInr;
  final double tradeFrequencyPerDay;
  final Duration tradingPeriod;

  const TradeHistoryStatistics({
    required this.totalTrades,
    required this.totalBuyTrades,
    required this.totalSellTrades,
    required this.winRate,
    required this.lossRate,
    required this.breakEvenRate,
    required this.largestGainInr,
    required this.largestLossInr,
    required this.averageGainInr,
    required this.averageLossInr,
    required this.profitFactor,
    required this.netRealizedProfitLossInr,
    required this.tradeFrequencyPerDay,
    required this.tradingPeriod,
  });
}

@immutable
class TradeHistorySummary {
  final int totalTrades;
  final int buyCount;
  final int sellCount;
  final double totalBuyVolumeInr;
  final double totalSellVolumeInr;
  final double realizedProfitInr;
  final double realizedLossInr;
  final double netRealizedProfitLossInr;
  final double largestGainInr;
  final double largestLossInr;
  final double averageGainInr;
  final double averageLossInr;
  final int profitableTrades;
  final int losingTrades;
  final int breakEvenTrades;
  final double cumulativeCashFlowInr;
  final DateTime? firstTradeTimestamp;
  final DateTime? lastTradeTimestamp;

  const TradeHistorySummary({
    required this.totalTrades,
    required this.buyCount,
    required this.sellCount,
    required this.totalBuyVolumeInr,
    required this.totalSellVolumeInr,
    required this.realizedProfitInr,
    required this.realizedLossInr,
    required this.netRealizedProfitLossInr,
    required this.largestGainInr,
    required this.largestLossInr,
    required this.averageGainInr,
    required this.averageLossInr,
    required this.profitableTrades,
    required this.losingTrades,
    required this.breakEvenTrades,
    required this.cumulativeCashFlowInr,
    required this.firstTradeTimestamp,
    required this.lastTradeTimestamp,
  });
}

@immutable
class TradeHistoryReplay {
  final List<Trade> orderedTrades;
  final List<TradeReplayStep> steps;
  final double endingCumulativeCashFlowInr;
  final double endingRealizedProfitLossInr;

  const TradeHistoryReplay({
    required this.orderedTrades,
    required this.steps,
    required this.endingCumulativeCashFlowInr,
    required this.endingRealizedProfitLossInr,
  });
}

@immutable
class TradeReplayStep {
  final int sequenceNumber;
  final Trade trade;
  final String assetSymbol;
  final TradeSide side;
  final DateTime executionTime;
  final double quantity;
  final double cashFlowInr;
  final double realizedProfitLossInr;
  final double runningCumulativeCashFlowInr;
  final double runningRealizedProfitLossInr;
  final double positionQuantityAfterTrade;
  final double positionCostBasisAfterTradeInr;
  final double averageEntryPriceAfterTradeInr;

  const TradeReplayStep({
    required this.sequenceNumber,
    required this.trade,
    required this.assetSymbol,
    required this.side,
    required this.executionTime,
    required this.quantity,
    required this.cashFlowInr,
    required this.realizedProfitLossInr,
    required this.runningCumulativeCashFlowInr,
    required this.runningRealizedProfitLossInr,
    required this.positionQuantityAfterTrade,
    required this.positionCostBasisAfterTradeInr,
    required this.averageEntryPriceAfterTradeInr,
  });
}
