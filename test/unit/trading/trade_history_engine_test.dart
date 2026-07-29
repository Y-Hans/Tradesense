import 'package:cryptoedu/features/trading/domain/trade_history_engine.dart';
import 'package:cryptoedu/features/trading/domain/trade_history_result.dart';
import 'package:cryptoedu/features/trading/domain/trading_failure.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TradeHistoryEngine.calculate', () {
    const engine = TradeHistoryEngine();
    final evaluatedAt = DateTime.utc(2026, 7, 29, 12);

    TradeHistoryResult calculate(
      List<Trade> trades, {
      DateTime? evaluationTime,
    }) {
      return engine.calculate(
        trades: trades,
        evaluatedAt: evaluationTime ?? evaluatedAt,
      );
    }

    TradeHistorySnapshot snapshot(TradeHistoryResult result) {
      expect(result, isA<TradeHistorySuccess>());
      return (result as TradeHistorySuccess).snapshot;
    }

    TradingFailureCode rejectedCode(TradeHistoryResult result) {
      expect(result, isA<TradeHistoryRejected>());
      return (result as TradeHistoryRejected).failure.code;
    }

    test('empty history returns immutable zero snapshot', () {
      final history = snapshot(calculate([]));

      expect(history.timeline, isEmpty);
      expect(history.assetAnalytics, isEmpty);
      expect(history.replay.orderedTrades, isEmpty);
      expect(history.replay.steps, isEmpty);
      expect(history.summary.totalTrades, 0);
      expect(history.summary.totalBuyVolumeInr, 0.0);
      expect(history.summary.totalSellVolumeInr, 0.0);
      expect(history.summary.netRealizedProfitLossInr, 0.0);
      expect(history.summary.firstTradeTimestamp, isNull);
      expect(history.summary.lastTradeTimestamp, isNull);
      expect(history.statistics.tradeFrequencyPerDay, 0.0);
      expect(history.statistics.tradingPeriod, Duration.zero);
      expect(history.evaluatedAt, evaluatedAt);
      expect(() => history.timeline.clear(), throwsUnsupportedError);
      expect(
        () => history.assetAnalytics.add(
          const AssetTradeAnalytics(
            assetSymbol: 'BTC',
            tradeCount: 0,
            buyCount: 0,
            sellCount: 0,
            realizedProfitInr: 0.0,
            realizedLossInr: 0.0,
            netRealizedProfitLossInr: 0.0,
            averageBuyPriceInr: 0.0,
            averageSellPriceInr: 0.0,
            largestTrade: null,
            lastTradeTime: null,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('omitted evaluation timestamp stays deterministic', () {
      final trade = _buy(timestamp: DateTime.utc(2026, 7, 29, 9));

      final first = snapshot(engine.calculate(trades: [trade]));
      final second = snapshot(engine.calculate(trades: [trade]));

      expect(first.evaluatedAt, trade.timestamp);
      expect(second.evaluatedAt, first.evaluatedAt);
    });

    test('single BUY creates outflow-only timeline and replay state', () {
      final trade = _buy(
        quantity: 2.0,
        totalAmountInr: 1000.0,
        executionPriceInr: 500.0,
      );

      final history = snapshot(calculate([trade]));

      expect(history.summary.totalTrades, 1);
      expect(history.summary.buyCount, 1);
      expect(history.summary.sellCount, 0);
      expect(history.summary.totalBuyVolumeInr, 1000.0);
      expect(history.summary.cumulativeCashFlowInr, -1000.0);
      expect(history.summary.netRealizedProfitLossInr, 0.0);
      expect(history.timeline.single.assetSymbol, 'BTC');
      expect(history.timeline.single.runningCumulativeCashFlowInr, -1000.0);
      expect(history.replay.steps.single.positionQuantityAfterTrade, 2.0);
      expect(
          history.replay.steps.single.positionCostBasisAfterTradeInr, 1000.0);
      expect(history.replay.steps.single.averageEntryPriceAfterTradeInr, 500.0);
    });

    test('single SELL without prior BUY is rejected', () {
      final result = calculate([
        _sell(quantity: 1.0, executionPriceInr: 600.0, totalAmountInr: 600.0),
      ]);

      expect(rejectedCode(result), TradingFailureCode.insufficientHoldings);
    });

    test('multiple BUY trades calculate weighted position replay', () {
      final history = snapshot(
        calculate([
          _buy(id: 'buy_1', quantity: 2.0, executionPriceInr: 100.0),
          _buy(id: 'buy_2', quantity: 1.0, executionPriceInr: 200.0),
        ]),
      );

      expect(history.summary.buyCount, 2);
      expect(history.summary.totalBuyVolumeInr, 400.0);
      expect(history.summary.cumulativeCashFlowInr, -400.0);
      expect(history.replay.steps.last.positionQuantityAfterTrade, 3.0);
      expect(history.replay.steps.last.positionCostBasisAfterTradeInr, 400.0);
      expect(history.replay.steps.last.averageEntryPriceAfterTradeInr,
          closeTo(133.33, 0.001));
    });

    test('multiple SELL trades calculate profit, loss, and break-even counts',
        () {
      final history = snapshot(
        calculate([
          _buy(id: 'buy_1', quantity: 3.0, executionPriceInr: 100.0),
          _sell(id: 'sell_gain', quantity: 1.0, executionPriceInr: 150.0),
          _sell(id: 'sell_loss', quantity: 1.0, executionPriceInr: 80.0),
          _sell(id: 'sell_even', quantity: 1.0, executionPriceInr: 100.0),
        ]),
      );

      expect(history.summary.sellCount, 3);
      expect(history.summary.totalSellVolumeInr, 330.0);
      expect(history.summary.realizedProfitInr, 50.0);
      expect(history.summary.realizedLossInr, -20.0);
      expect(history.summary.netRealizedProfitLossInr, 30.0);
      expect(history.summary.profitableTrades, 1);
      expect(history.summary.losingTrades, 1);
      expect(history.summary.breakEvenTrades, 1);
    });

    test('mixed assets calculate independent asset analytics', () {
      final history = snapshot(
        calculate([
          _buy(id: 'btc_buy', symbol: 'btc', quantity: 2.0),
          _sell(
            id: 'btc_sell',
            symbol: 'BTC',
            quantity: 1.0,
            executionPriceInr: 120.0,
          ),
          _buy(
            id: 'eth_buy',
            symbol: 'ETH',
            quantity: 10.0,
            executionPriceInr: 20.0,
          ),
          _sell(
            id: 'eth_sell',
            symbol: 'eth',
            quantity: 5.0,
            executionPriceInr: 10.0,
          ),
        ]),
      );

      expect(history.assetAnalytics.map((asset) => asset.assetSymbol),
          ['BTC', 'ETH']);
      final btc = history.assetAnalytics.first;
      final eth = history.assetAnalytics.last;
      expect(btc.tradeCount, 2);
      expect(btc.buyCount, 1);
      expect(btc.sellCount, 1);
      expect(btc.netRealizedProfitLossInr, 20.0);
      expect(btc.averageBuyPriceInr, 100.0);
      expect(btc.averageSellPriceInr, 120.0);
      expect(btc.largestTrade?.trade.id, 'btc_buy');
      expect(eth.netRealizedProfitLossInr, -50.0);
      expect(eth.averageBuyPriceInr, 20.0);
      expect(eth.averageSellPriceInr, 10.0);
    });

    test('chronological sorting ignores input ordering', () {
      final early = DateTime.utc(2026, 7, 29, 8);
      final late = DateTime.utc(2026, 7, 29, 10);
      final history = snapshot(
        calculate([
          _sell(id: 'sell_1', quantity: 1.0, timestamp: late),
          _buy(id: 'buy_1', quantity: 1.0, timestamp: early),
        ]),
      );

      expect(
          history.timeline.map((entry) => entry.trade.id), ['buy_1', 'sell_1']);
      expect(history.summary.firstTradeTimestamp, early);
      expect(history.summary.lastTradeTimestamp, late);
    });

    test('duplicate timestamps sort by trade ID', () {
      final sameTime = DateTime.utc(2026, 7, 29, 9);
      final history = snapshot(
        calculate([
          _buy(id: 'buy_b', quantity: 1.0, timestamp: sameTime),
          _buy(id: 'buy_a', quantity: 1.0, timestamp: sameTime),
        ]),
      );

      expect(
        history.replay.orderedTrades.map((trade) => trade.id),
        ['buy_a', 'buy_b'],
      );
    });

    test('duplicate IDs are rejected', () {
      final result = calculate([
        _buy(id: 'same_id'),
        _buy(id: 'same_id', quantity: 2.0),
      ]);

      expect(rejectedCode(result), TradingFailureCode.invalidTradeMetadata);
    });

    test('profit statistics calculate win rate, largest gain, and factor', () {
      final history = snapshot(
        calculate([
          _buy(id: 'buy_1', quantity: 2.0, executionPriceInr: 100.0),
          _sell(id: 'sell_1', quantity: 1.0, executionPriceInr: 130.0),
          _sell(id: 'sell_2', quantity: 1.0, executionPriceInr: 150.0),
        ]),
      );

      expect(history.statistics.winRate, 100.0);
      expect(history.statistics.lossRate, 0.0);
      expect(history.statistics.breakEvenRate, 0.0);
      expect(history.statistics.largestGainInr, 50.0);
      expect(history.statistics.averageGainInr, 40.0);
      expect(history.statistics.profitFactor, double.infinity);
    });

    test('loss statistics calculate loss rate and largest loss', () {
      final history = snapshot(
        calculate([
          _buy(id: 'buy_1', quantity: 2.0, executionPriceInr: 100.0),
          _sell(id: 'sell_1', quantity: 1.0, executionPriceInr: 90.0),
          _sell(id: 'sell_2', quantity: 1.0, executionPriceInr: 70.0),
        ]),
      );

      expect(history.statistics.winRate, 0.0);
      expect(history.statistics.lossRate, 100.0);
      expect(history.statistics.largestLossInr, -30.0);
      expect(history.statistics.averageLossInr, -20.0);
      expect(history.statistics.profitFactor, 0.0);
    });

    test('break-even rate is based on realized SELL trades', () {
      final history = snapshot(
        calculate([
          _buy(id: 'buy_1', quantity: 2.0, executionPriceInr: 100.0),
          _sell(id: 'sell_even', quantity: 1.0, executionPriceInr: 100.0),
          _sell(id: 'sell_gain', quantity: 1.0, executionPriceInr: 120.0),
        ]),
      );

      expect(history.summary.breakEvenTrades, 1);
      expect(history.statistics.breakEvenRate, 50.0);
      expect(history.statistics.winRate, 50.0);
    });

    test('running cash flow and realized P&L are exposed on timeline', () {
      final history = snapshot(
        calculate([
          _buy(id: 'buy_1', quantity: 2.0, executionPriceInr: 100.0),
          _sell(id: 'sell_1', quantity: 0.5, executionPriceInr: 140.0),
          _sell(id: 'sell_2', quantity: 0.5, executionPriceInr: 60.0),
        ]),
      );

      expect(history.timeline[0].runningCumulativeCashFlowInr, -200.0);
      expect(history.timeline[0].runningRealizedProfitLossInr, 0.0);
      expect(history.timeline[1].runningCumulativeCashFlowInr, -130.0);
      expect(history.timeline[1].realizedProfitLossInr, 20.0);
      expect(history.timeline[1].runningRealizedProfitLossInr, 20.0);
      expect(history.timeline[2].runningCumulativeCashFlowInr, -100.0);
      expect(history.timeline[2].realizedProfitLossInr, -20.0);
      expect(history.timeline[2].runningRealizedProfitLossInr, 0.0);
    });

    test('replay steps expose deterministic reconstruction state', () {
      final history = snapshot(
        calculate([
          _buy(id: 'buy_1', quantity: 2.0, executionPriceInr: 100.0),
          _sell(id: 'sell_1', quantity: 0.5, executionPriceInr: 140.0),
        ]),
      );

      final step = history.replay.steps.last;
      expect(step.sequenceNumber, 2);
      expect(step.trade.id, 'sell_1');
      expect(step.cashFlowInr, 70.0);
      expect(step.realizedProfitLossInr, 20.0);
      expect(step.positionQuantityAfterTrade, 1.5);
      expect(step.positionCostBasisAfterTradeInr, 150.0);
      expect(step.averageEntryPriceAfterTradeInr, 100.0);
      expect(history.replay.endingCumulativeCashFlowInr, -130.0);
      expect(history.replay.endingRealizedProfitLossInr, 20.0);
    });

    test('trade frequency and trading period are deterministic', () {
      final first = DateTime.utc(2026, 7, 28, 9);
      final last = DateTime.utc(2026, 7, 30, 9);
      final history = snapshot(
        calculate(
          [
            _buy(id: 'buy_1', timestamp: first),
            _buy(id: 'buy_2', timestamp: first.add(const Duration(days: 1))),
            _buy(id: 'buy_3', timestamp: last),
          ],
          evaluationTime: DateTime.utc(2026, 7, 30, 10),
        ),
      );

      expect(history.statistics.tradingPeriod, const Duration(days: 2));
      expect(history.statistics.tradeFrequencyPerDay, 1.5);
    });

    test('same valid input produces equivalent snapshots', () {
      final trades = [
        _buy(id: 'buy_1', quantity: 2.0),
        _sell(id: 'sell_1', quantity: 1.0, executionPriceInr: 130.0),
      ];

      final first = snapshot(calculate(trades));
      final second = snapshot(calculate(trades.reversed.toList()));

      expect(second.summary.netRealizedProfitLossInr,
          first.summary.netRealizedProfitLossInr);
      expect(second.timeline.map((entry) => entry.trade.id),
          first.timeline.map((entry) => entry.trade.id));
      expect(second.assetAnalytics.single.netRealizedProfitLossInr,
          first.assetAnalytics.single.netRealizedProfitLossInr);
      expect(second.replay.steps.last.positionQuantityAfterTrade,
          first.replay.steps.last.positionQuantityAfterTrade);
    });

    test('calculation does not mutate input trades or input list', () {
      final trade = _buy(id: 'buy_1', quantity: 2.0);
      final trades = [trade];
      final before = trade.toJson();

      final history = snapshot(calculate(trades));

      expect(trade.toJson(), before);
      expect(trades.single, same(trade));
      expect(history.timeline.single.trade, same(trade));
      expect(() => history.replay.orderedTrades.add(trade),
          throwsUnsupportedError);
      expect(() => history.replay.steps.add(history.replay.steps.single),
          throwsUnsupportedError);
    });

    test('invalid data is rejected with TradingFailure', () {
      expect(
        rejectedCode(calculate([_buy(id: '')])),
        TradingFailureCode.invalidTradeMetadata,
      );
      expect(
        rejectedCode(calculate([_buy(quantity: -1.0)])),
        TradingFailureCode.invalidTradeMetadata,
      );
      expect(
        rejectedCode(calculate([_buy(executionPriceInr: -1.0)])),
        TradingFailureCode.invalidTradeMetadata,
      );
      expect(
        rejectedCode(calculate([_buy(totalAmountInr: -1.0)])),
        TradingFailureCode.invalidTradeMetadata,
      );
      expect(
        rejectedCode(calculate([_buy(symbol: ' ')])),
        TradingFailureCode.invalidTradeMetadata,
      );
      expect(
        rejectedCode(
          calculate([
            _buy(timestamp: evaluatedAt.add(const Duration(seconds: 1))),
          ]),
        ),
        TradingFailureCode.invalidTradeMetadata,
      );
    });
  });
}

Trade _buy({
  String id = 'buy_1',
  String userId = 'user_1',
  String symbol = 'BTC',
  double quantity = 1.0,
  double executionPriceInr = 100.0,
  double? totalAmountInr,
  DateTime? timestamp,
}) {
  return _trade(
    id: id,
    userId: userId,
    symbol: symbol,
    side: TradeSide.buy,
    quantity: quantity,
    executionPriceInr: executionPriceInr,
    totalAmountInr: totalAmountInr ?? quantity * executionPriceInr,
    timestamp: timestamp,
  );
}

Trade _sell({
  String id = 'sell_1',
  String userId = 'user_1',
  String symbol = 'BTC',
  double quantity = 1.0,
  double executionPriceInr = 100.0,
  double? totalAmountInr,
  DateTime? timestamp,
}) {
  return _trade(
    id: id,
    userId: userId,
    symbol: symbol,
    side: TradeSide.sell,
    quantity: quantity,
    executionPriceInr: executionPriceInr,
    totalAmountInr: totalAmountInr ?? quantity * executionPriceInr,
    timestamp: timestamp,
  );
}

Trade _trade({
  required String id,
  required String userId,
  required String symbol,
  required TradeSide side,
  required double quantity,
  required double executionPriceInr,
  required double totalAmountInr,
  DateTime? timestamp,
}) {
  return Trade(
    id: id,
    userId: userId,
    symbol: symbol,
    side: side,
    type: OrderType.market,
    quantity: quantity,
    executionPriceInr: executionPriceInr,
    totalAmountInr: totalAmountInr,
    timestamp: timestamp ?? DateTime.utc(2026, 7, 29, 9),
    disciplineScoreAtTrade: 80,
    riskScoreAtTrade: 25,
  );
}
