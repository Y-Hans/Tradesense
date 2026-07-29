import 'package:decimal/decimal.dart';

import '../../../core/utils/financial_math.dart';
import '../../../shared/models/trade.dart';
import 'trade_history_result.dart';
import 'trading_failure.dart';

class TradeHistoryEngine {
  static const int cryptoQuantityScale = 18;
  static const int percentScale = 4;

  const TradeHistoryEngine();

  TradeHistoryResult calculate({
    required List<Trade> trades,
    DateTime? evaluatedAt,
  }) {
    final metadataFailure = _validateTrades(trades, evaluatedAt);
    if (metadataFailure != null) return TradeHistoryRejected(metadataFailure);

    final orderedTrades = List<Trade>.of(trades)
      ..sort(
        (left, right) {
          final timestampCompare = left.timestamp.compareTo(right.timestamp);
          if (timestampCompare != 0) return timestampCompare;
          return left.id.compareTo(right.id);
        },
      );

    final resolvedEvaluatedAt =
        evaluatedAt ?? _lastTimestamp(orderedTrades) ?? _emptyEvaluationTime;
    final positions = <String, _HistoryPosition>{};
    final assetWorkItems = <String, _AssetAnalyticsWorkItem>{};
    final timeline = <TradeTimelineEntry>[];
    final replaySteps = <TradeReplayStep>[];
    final sellProfitLosses = <Decimal>[];

    var totalBuyVolume = Decimal.zero;
    var totalSellVolume = Decimal.zero;
    var realizedProfit = Decimal.zero;
    var realizedLoss = Decimal.zero;
    var cumulativeCashFlow = Decimal.zero;
    var runningRealizedProfitLoss = Decimal.zero;
    var buyCount = 0;
    var sellCount = 0;
    var profitableTrades = 0;
    var losingTrades = 0;
    var breakEvenTrades = 0;

    for (var index = 0; index < orderedTrades.length; index++) {
      final trade = orderedTrades[index];
      final symbol = _normalizeSymbol(trade.symbol);
      final position = positions.putIfAbsent(symbol, _HistoryPosition.new);
      final assetWorkItem = assetWorkItems.putIfAbsent(
        symbol,
        () => _AssetAnalyticsWorkItem(symbol),
      );
      final quantity = _decimalFromDouble(trade.quantity);
      final totalAmount = _decimalFromDouble(trade.totalAmountInr);
      final executionPrice = _decimalFromDouble(trade.executionPriceInr);
      final cashFlow = trade.side == TradeSide.buy ? -totalAmount : totalAmount;
      var realizedProfitLoss = Decimal.zero;

      if (trade.side == TradeSide.buy) {
        position.quantity += quantity;
        position.costBasis += totalAmount;
        totalBuyVolume += totalAmount;
        buyCount++;
        assetWorkItem.buyCount++;
        assetWorkItem.buyQuantity += quantity;
        assetWorkItem.buyVolume += totalAmount;
      } else {
        if (quantity > position.quantity) {
          return const TradeHistoryRejected(
            TradingFailure(
              code: TradingFailureCode.insufficientHoldings,
              message:
                  'Trade history sells more quantity than it previously buys.',
            ),
          );
        }

        final removedCostBasis = position.quantity == Decimal.zero
            ? Decimal.zero
            : _divide(
                position.costBasis * quantity,
                position.quantity,
                scale: cryptoQuantityScale,
              );
        realizedProfitLoss = totalAmount - removedCostBasis;
        position.quantity -= quantity;
        position.costBasis = position.quantity == Decimal.zero
            ? Decimal.zero
            : position.costBasis - removedCostBasis;

        totalSellVolume += totalAmount;
        sellCount++;
        assetWorkItem.sellCount++;
        assetWorkItem.sellQuantity += quantity;
        assetWorkItem.sellVolume += totalAmount;
        sellProfitLosses.add(realizedProfitLoss);

        if (realizedProfitLoss > Decimal.zero) {
          realizedProfit += realizedProfitLoss;
          assetWorkItem.realizedProfit += realizedProfitLoss;
          profitableTrades++;
        } else if (realizedProfitLoss < Decimal.zero) {
          realizedLoss += realizedProfitLoss;
          assetWorkItem.realizedLoss += realizedProfitLoss;
          losingTrades++;
        } else {
          breakEvenTrades++;
        }
      }

      cumulativeCashFlow += cashFlow;
      runningRealizedProfitLoss += realizedProfitLoss;

      final timelineEntry = TradeTimelineEntry(
        trade: trade,
        assetSymbol: symbol,
        side: trade.side,
        executionTime: trade.timestamp,
        quantity: quantity.toDouble(),
        executionPriceInr: _inrDouble(executionPrice),
        totalValueInr: _inrDouble(totalAmount),
        realizedProfitLossInr: _inrDouble(realizedProfitLoss),
        runningCumulativeCashFlowInr: _inrDouble(cumulativeCashFlow),
        runningRealizedProfitLossInr: _inrDouble(runningRealizedProfitLoss),
      );
      timeline.add(timelineEntry);

      assetWorkItem.tradeCount++;
      assetWorkItem.lastTradeTime = trade.timestamp;
      if (assetWorkItem.largestTrade == null ||
          totalAmount >
              _decimalFromDouble(assetWorkItem.largestTrade!.totalValueInr)) {
        assetWorkItem.largestTrade = timelineEntry;
      }

      final averageEntry = position.quantity == Decimal.zero
          ? Decimal.zero
          : _divide(
              position.costBasis,
              position.quantity,
              scale: cryptoQuantityScale,
            );
      replaySteps.add(
        TradeReplayStep(
          sequenceNumber: index + 1,
          trade: trade,
          assetSymbol: symbol,
          side: trade.side,
          executionTime: trade.timestamp,
          quantity: quantity.toDouble(),
          cashFlowInr: _inrDouble(cashFlow),
          realizedProfitLossInr: _inrDouble(realizedProfitLoss),
          runningCumulativeCashFlowInr: _inrDouble(cumulativeCashFlow),
          runningRealizedProfitLossInr: _inrDouble(runningRealizedProfitLoss),
          positionQuantityAfterTrade: position.quantity.toDouble(),
          positionCostBasisAfterTradeInr: _inrDouble(position.costBasis),
          averageEntryPriceAfterTradeInr: _inrDouble(averageEntry),
        ),
      );
    }

    final largestGain = _maxPositive(sellProfitLosses);
    final largestLoss = _minNegative(sellProfitLosses);
    final averageGain = _averageMatching(
      sellProfitLosses,
      (value) => value > Decimal.zero,
    );
    final averageLoss = _averageMatching(
      sellProfitLosses,
      (value) => value < Decimal.zero,
    );
    final netRealizedProfitLoss = realizedProfit + realizedLoss;
    final firstTradeTimestamp =
        orderedTrades.isEmpty ? null : orderedTrades.first.timestamp;
    final lastTradeTimestamp = _lastTimestamp(orderedTrades);
    final tradingPeriod =
        firstTradeTimestamp == null || lastTradeTimestamp == null
            ? Duration.zero
            : lastTradeTimestamp.difference(firstTradeTimestamp);

    final assetAnalytics = assetWorkItems.values.toList(growable: false)
      ..sort((left, right) => left.assetSymbol.compareTo(right.assetSymbol));

    final summary = TradeHistorySummary(
      totalTrades: orderedTrades.length,
      buyCount: buyCount,
      sellCount: sellCount,
      totalBuyVolumeInr: _inrDouble(totalBuyVolume),
      totalSellVolumeInr: _inrDouble(totalSellVolume),
      realizedProfitInr: _inrDouble(realizedProfit),
      realizedLossInr: _inrDouble(realizedLoss),
      netRealizedProfitLossInr: _inrDouble(netRealizedProfitLoss),
      largestGainInr: _inrDouble(largestGain),
      largestLossInr: _inrDouble(largestLoss),
      averageGainInr: _inrDouble(averageGain),
      averageLossInr: _inrDouble(averageLoss),
      profitableTrades: profitableTrades,
      losingTrades: losingTrades,
      breakEvenTrades: breakEvenTrades,
      cumulativeCashFlowInr: _inrDouble(cumulativeCashFlow),
      firstTradeTimestamp: firstTradeTimestamp,
      lastTradeTimestamp: lastTradeTimestamp,
    );

    final statistics = TradeHistoryStatistics(
      totalTrades: orderedTrades.length,
      totalBuyTrades: buyCount,
      totalSellTrades: sellCount,
      winRate: _rate(profitableTrades, sellCount),
      lossRate: _rate(losingTrades, sellCount),
      breakEvenRate: _rate(breakEvenTrades, sellCount),
      largestGainInr: summary.largestGainInr,
      largestLossInr: summary.largestLossInr,
      averageGainInr: summary.averageGainInr,
      averageLossInr: summary.averageLossInr,
      profitFactor: _profitFactor(realizedProfit, realizedLoss),
      netRealizedProfitLossInr: summary.netRealizedProfitLossInr,
      tradeFrequencyPerDay: _tradeFrequencyPerDay(
        orderedTrades.length,
        tradingPeriod,
      ),
      tradingPeriod: tradingPeriod,
    );

    final snapshot = TradeHistorySnapshot(
      timeline: List<TradeTimelineEntry>.unmodifiable(timeline),
      assetAnalytics: List<AssetTradeAnalytics>.unmodifiable(
        assetAnalytics.map(
          (item) => AssetTradeAnalytics(
            assetSymbol: item.assetSymbol,
            tradeCount: item.tradeCount,
            buyCount: item.buyCount,
            sellCount: item.sellCount,
            realizedProfitInr: _inrDouble(item.realizedProfit),
            realizedLossInr: _inrDouble(item.realizedLoss),
            netRealizedProfitLossInr:
                _inrDouble(item.realizedProfit + item.realizedLoss),
            averageBuyPriceInr: _averagePrice(
              item.buyVolume,
              item.buyQuantity,
            ),
            averageSellPriceInr: _averagePrice(
              item.sellVolume,
              item.sellQuantity,
            ),
            largestTrade: item.largestTrade,
            lastTradeTime: item.lastTradeTime,
          ),
        ),
      ),
      statistics: statistics,
      summary: summary,
      replay: TradeHistoryReplay(
        orderedTrades: List<Trade>.unmodifiable(orderedTrades),
        steps: List<TradeReplayStep>.unmodifiable(replaySteps),
        endingCumulativeCashFlowInr: summary.cumulativeCashFlowInr,
        endingRealizedProfitLossInr: summary.netRealizedProfitLossInr,
      ),
      evaluatedAt: resolvedEvaluatedAt,
    );

    return TradeHistorySuccess(snapshot: snapshot);
  }

  TradingFailure? _validateTrades(List<Trade> trades, DateTime? evaluatedAt) {
    final seenTradeIds = <String>{};
    for (final trade in trades) {
      final tradeId = trade.id.trim();
      if (tradeId.isEmpty ||
          trade.userId.trim().isEmpty ||
          _normalizeSymbol(trade.symbol).isEmpty ||
          !trade.quantity.isFinite ||
          !trade.executionPriceInr.isFinite ||
          !trade.totalAmountInr.isFinite ||
          trade.quantity <= 0 ||
          trade.executionPriceInr <= 0 ||
          trade.totalAmountInr <= 0 ||
          trade.disciplineScoreAtTrade < 0 ||
          trade.riskScoreAtTrade < 0) {
        return const TradingFailure(
          code: TradingFailureCode.invalidTradeMetadata,
          message: 'Trade history contains invalid financial state.',
        );
      }
      if (!seenTradeIds.add(tradeId)) {
        return const TradingFailure(
          code: TradingFailureCode.invalidTradeMetadata,
          message: 'Trade history contains duplicate trade identifiers.',
        );
      }
      if (evaluatedAt != null && trade.timestamp.isAfter(evaluatedAt)) {
        return const TradingFailure(
          code: TradingFailureCode.invalidTradeMetadata,
          message: 'Trade history contains timestamps after evaluation time.',
        );
      }
    }
    return null;
  }

  String _normalizeSymbol(String symbol) => symbol.trim().toUpperCase();

  Decimal _decimalFromDouble(double value) => Decimal.parse(value.toString());

  double _inrDouble(Decimal value) {
    return FinancialMath.paiseToInr(FinancialMath.inrToPaise(value.toDouble()));
  }

  double _rate(int count, int denominator) {
    if (denominator == 0) return 0.0;
    return _divide(
      Decimal.fromInt(count * 100),
      Decimal.fromInt(denominator),
      scale: percentScale,
    ).toDouble();
  }

  double _profitFactor(Decimal profit, Decimal loss) {
    if (profit == Decimal.zero && loss == Decimal.zero) return 0.0;
    if (loss == Decimal.zero) return double.infinity;
    return _divide(profit, loss.abs(), scale: percentScale).toDouble();
  }

  double _tradeFrequencyPerDay(int totalTrades, Duration tradingPeriod) {
    if (totalTrades == 0) return 0.0;
    if (tradingPeriod == Duration.zero) return totalTrades.toDouble();
    final days = Decimal.parse(
      (tradingPeriod.inMicroseconds / Duration.microsecondsPerDay).toString(),
    );
    return _divide(
      Decimal.fromInt(totalTrades),
      days,
      scale: percentScale,
    ).toDouble();
  }

  double _averagePrice(Decimal volume, Decimal quantity) {
    if (quantity == Decimal.zero) return 0.0;
    return _inrDouble(
      _divide(volume, quantity, scale: cryptoQuantityScale),
    );
  }

  Decimal _maxPositive(List<Decimal> values) {
    final positives = values.where((value) => value > Decimal.zero);
    if (positives.isEmpty) return Decimal.zero;
    return positives.reduce((best, current) => current > best ? current : best);
  }

  Decimal _minNegative(List<Decimal> values) {
    final negatives = values.where((value) => value < Decimal.zero);
    if (negatives.isEmpty) return Decimal.zero;
    return negatives.reduce((best, current) => current < best ? current : best);
  }

  Decimal _averageMatching(
    List<Decimal> values,
    bool Function(Decimal value) matches,
  ) {
    final matched = values.where(matches).toList(growable: false);
    if (matched.isEmpty) return Decimal.zero;
    final total = matched.fold(Decimal.zero, (sum, value) => sum + value);
    return _divide(
      total,
      Decimal.fromInt(matched.length),
      scale: cryptoQuantityScale,
    );
  }

  DateTime? _lastTimestamp(List<Trade> orderedTrades) {
    return orderedTrades.isEmpty ? null : orderedTrades.last.timestamp;
  }

  Decimal _divide(
    Decimal numerator,
    Decimal denominator, {
    required int scale,
  }) {
    return (numerator / denominator).toDecimal(
      scaleOnInfinitePrecision: scale,
    );
  }

  DateTime get _emptyEvaluationTime =>
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

class _HistoryPosition {
  Decimal quantity = Decimal.zero;
  Decimal costBasis = Decimal.zero;
}

class _AssetAnalyticsWorkItem {
  final String assetSymbol;
  int tradeCount = 0;
  int buyCount = 0;
  int sellCount = 0;
  Decimal realizedProfit = Decimal.zero;
  Decimal realizedLoss = Decimal.zero;
  Decimal buyQuantity = Decimal.zero;
  Decimal sellQuantity = Decimal.zero;
  Decimal buyVolume = Decimal.zero;
  Decimal sellVolume = Decimal.zero;
  TradeTimelineEntry? largestTrade;
  DateTime? lastTradeTime;

  _AssetAnalyticsWorkItem(this.assetSymbol);
}
