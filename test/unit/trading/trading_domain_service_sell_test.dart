import 'package:cryptoedu/features/trading/domain/sell_trade_result.dart';
import 'package:cryptoedu/features/trading/domain/trading_domain_service.dart';
import 'package:cryptoedu/features/trading/domain/trading_failure.dart';
import 'package:cryptoedu/shared/models/holding.dart';
import 'package:cryptoedu/shared/models/market_ticker.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TradingDomainService.calculateSell', () {
    const service = TradingDomainService();
    final evaluatedAt = DateTime.utc(2026, 7, 29, 10);
    final executedAt = DateTime.utc(2026, 7, 29, 10, 0, 5);

    SellTradeResult calculate({
      VirtualWallet? wallet,
      String walletUserId = 'user_1',
      Holding? existingHolding,
      MarketTicker? ticker,
      double sellQuantity = 0.5,
      String userId = 'user_1',
    }) {
      return service.calculateSell(
        wallet: wallet ?? _wallet(),
        walletUserId: walletUserId,
        existingHolding: existingHolding ?? _holding(),
        ticker: ticker ?? _ticker(timestamp: evaluatedAt),
        sellQuantity: sellQuantity,
        executedAt: executedAt,
        evaluatedAt: evaluatedAt,
        tradeId: 'trade_sell_1',
        userId: userId,
        disciplineScoreAtTrade: 82,
        riskScoreAtTrade: 24,
      );
    }

    TradingFailureCode rejectedCode(SellTradeResult result) {
      expect(result, isA<SellTradeRejected>());
      return (result as SellTradeRejected).failure.code;
    }

    test('successful first sell updates wallet, holding, and creates trade',
        () {
      final wallet = _wallet(balanceInr: 1000000.0);
      final holding = _holding(
        quantity: 2.0,
        averageEntryPriceInr: 4000000.0,
        currentPriceInr: 4000000.0,
      );
      final ticker = _ticker(priceInr: 5000000.0, timestamp: evaluatedAt);

      final result = calculate(
        wallet: wallet,
        existingHolding: holding,
        ticker: ticker,
        sellQuantity: 0.5,
      );

      expect(result, isA<SellTradeSuccess>());
      final success = result as SellTradeSuccess;
      expect(success.saleProceedsInr, 2500000.0);
      expect(success.soldQuantity, 0.5);
      expect(success.executionPriceInr, 5000000.0);
      expect(success.previousWalletBalanceInr, 1000000.0);
      expect(success.newWalletBalanceInr, 3500000.0);
      expect(success.updatedWallet.balanceInr, 3500000.0);
      expect(success.previousHoldingQuantity, 2.0);
      expect(success.newHoldingQuantity, 1.5);
      expect(success.updatedHolding.quantity, 1.5);
      expect(success.updatedHolding.averageEntryPriceInr, 4000000.0);
      expect(success.updatedHolding.currentPriceInr, 5000000.0);
      expect(success.previousCostBasisInr, 8000000.0);
      expect(success.removedCostBasisInr, 2000000.0);
      expect(success.remainingCostBasisInr, 6000000.0);
      expect(success.realizedProfitLossInr, 500000.0);

      expect(success.trade.id, 'trade_sell_1');
      expect(success.trade.userId, 'user_1');
      expect(success.trade.symbol, 'BTC');
      expect(success.trade.side, TradeSide.sell);
      expect(success.trade.type, OrderType.market);
      expect(success.trade.quantity, 0.5);
      expect(success.trade.executionPriceInr, 5000000.0);
      expect(success.trade.totalAmountInr, 2500000.0);
      expect(success.trade.timestamp, executedAt);
      expect(success.trade.disciplineScoreAtTrade, 82);
      expect(success.trade.riskScoreAtTrade, 24);

      expect(wallet.balanceInr, 1000000.0);
      expect(holding.quantity, 2.0);
      expect(ticker.priceInr, 5000000.0);
    });

    test('partial sell preserves historical average entry price', () {
      final result = calculate(
        existingHolding: _holding(
          quantity: 3.0,
          averageEntryPriceInr: 120.0,
          currentPriceInr: 130.0,
        ),
        ticker: _ticker(priceInr: 150.0, timestamp: evaluatedAt),
        sellQuantity: 1.0,
      );

      expect(result, isA<SellTradeSuccess>());
      final success = result as SellTradeSuccess;
      expect(success.previousCostBasisInr, 360.0);
      expect(success.removedCostBasisInr, 120.0);
      expect(success.remainingCostBasisInr, 240.0);
      expect(success.newHoldingQuantity, 2.0);
      expect(success.previousAverageEntryPriceInr, 120.0);
      expect(success.newAverageEntryPriceInr, 120.0);
      expect(success.updatedHolding.averageEntryPriceInr, 120.0);
      expect(success.newAverageEntryPriceInr, isNot(150.0));
    });

    test('full sell leaves an empty holding using existing model conventions',
        () {
      final result = calculate(
        existingHolding: _holding(
          quantity: 2.0,
          averageEntryPriceInr: 4000000.0,
          currentPriceInr: 4000000.0,
        ),
        ticker: _ticker(priceInr: 4500000.0, timestamp: evaluatedAt),
        sellQuantity: 2.0,
      );

      expect(result, isA<SellTradeSuccess>());
      final success = result as SellTradeSuccess;
      expect(success.saleProceedsInr, 9000000.0);
      expect(success.removedCostBasisInr, 8000000.0);
      expect(success.remainingCostBasisInr, 0.0);
      expect(success.realizedProfitLossInr, 1000000.0);
      expect(success.updatedHolding.quantity, 0.0);
      expect(success.updatedHolding.averageEntryPriceInr, 0.0);
      expect(success.updatedHolding.currentPriceInr, 4500000.0);
    });

    test('oversell is rejected without mutating inputs', () {
      final holding = _holding(quantity: 1.0);
      final wallet = _wallet(balanceInr: 1000.0);

      final result = calculate(
        wallet: wallet,
        existingHolding: holding,
        sellQuantity: 1.0000000000000002,
      );

      expect(rejectedCode(result), TradingFailureCode.insufficientHoldings);
      expect(wallet.balanceInr, 1000.0);
      expect(holding.quantity, 1.0);
    });

    test('zero and negative quantities are rejected', () {
      expect(rejectedCode(calculate(sellQuantity: 0.0)),
          TradingFailureCode.invalidSellQuantity);
      expect(rejectedCode(calculate(sellQuantity: -0.1)),
          TradingFailureCode.invalidSellQuantity);
    });

    test('non-finite quantities are rejected', () {
      expect(rejectedCode(calculate(sellQuantity: double.nan)),
          TradingFailureCode.invalidSellQuantity);
      expect(rejectedCode(calculate(sellQuantity: double.infinity)),
          TradingFailureCode.invalidSellQuantity);
    });

    test('missing holding is rejected', () {
      final result = service.calculateSell(
        wallet: _wallet(),
        walletUserId: 'user_1',
        existingHolding: null,
        ticker: _ticker(timestamp: evaluatedAt),
        sellQuantity: 0.5,
        executedAt: executedAt,
        evaluatedAt: evaluatedAt,
        tradeId: 'trade_sell_1',
        userId: 'user_1',
        disciplineScoreAtTrade: 82,
        riskScoreAtTrade: 24,
      );

      expect(rejectedCode(result), TradingFailureCode.missingHolding);
    });

    test('stale ticker is rejected using caller supplied evaluation time', () {
      final result = calculate(
        ticker: _ticker(
          timestamp: evaluatedAt.subtract(const Duration(seconds: 31)),
        ),
      );

      expect(rejectedCode(result), TradingFailureCode.staleTicker);
    });

    test('ticker for the wrong asset is rejected', () {
      final result = calculate(
        existingHolding: _holding(symbol: 'BTC'),
        ticker: _ticker(symbol: 'ETH', timestamp: evaluatedAt),
      );

      expect(rejectedCode(result), TradingFailureCode.mismatchedTicker);
    });

    test('foreign wallet state cannot be used for a sell', () {
      final result = calculate(walletUserId: 'user_2');

      expect(
        rejectedCode(result),
        TradingFailureCode.walletOwnershipMismatch,
      );
    });

    test('foreign holding state cannot be used for a sell', () {
      final result = calculate(existingHolding: _holding(userId: 'user_2'));

      expect(
        rejectedCode(result),
        TradingFailureCode.holdingOwnershipMismatch,
      );
    });

    test('profit, loss, and break-even realized P&L use proportional basis',
        () {
      final profit = calculate(
        existingHolding: _holding(quantity: 2.0, averageEntryPriceInr: 100.0),
        ticker: _ticker(priceInr: 130.0, timestamp: evaluatedAt),
        sellQuantity: 0.5,
      ) as SellTradeSuccess;
      final loss = calculate(
        existingHolding: _holding(quantity: 2.0, averageEntryPriceInr: 100.0),
        ticker: _ticker(priceInr: 80.0, timestamp: evaluatedAt),
        sellQuantity: 0.5,
      ) as SellTradeSuccess;
      final breakEven = calculate(
        existingHolding: _holding(quantity: 2.0, averageEntryPriceInr: 100.0),
        ticker: _ticker(priceInr: 100.0, timestamp: evaluatedAt),
        sellQuantity: 0.5,
      ) as SellTradeSuccess;

      expect(profit.removedCostBasisInr, 50.0);
      expect(profit.realizedProfitLossInr, 15.0);
      expect(loss.removedCostBasisInr, 50.0);
      expect(loss.realizedProfitLossInr, -10.0);
      expect(breakEven.removedCostBasisInr, 50.0);
      expect(breakEven.realizedProfitLossInr, 0.0);
    });

    test('wallet update adds rounded sale proceeds to cash balance', () {
      final result = calculate(
        wallet: _wallet(balanceInr: 100.0),
        existingHolding: _holding(quantity: 1.0, averageEntryPriceInr: 10.0),
        ticker: _ticker(priceInr: 33.333, timestamp: evaluatedAt),
        sellQuantity: 0.3,
      );

      expect(result, isA<SellTradeSuccess>());
      final success = result as SellTradeSuccess;
      expect(success.saleProceedsInr, 10.0);
      expect(success.updatedWallet.balanceInr, 110.0);
      expect(success.updatedWallet.lockedInr, 0.0);
    });

    test('same valid input produces equivalent results', () {
      final wallet = _wallet();
      final holding = _holding();
      final ticker = _ticker(timestamp: evaluatedAt);

      final first = calculate(
        wallet: wallet,
        existingHolding: holding,
        ticker: ticker,
      );
      final second = calculate(
        wallet: wallet,
        existingHolding: holding,
        ticker: ticker,
      );

      expect(first, isA<SellTradeSuccess>());
      expect(second, isA<SellTradeSuccess>());
      final firstSuccess = first as SellTradeSuccess;
      final secondSuccess = second as SellTradeSuccess;
      expect(secondSuccess.updatedWallet.toJson(),
          firstSuccess.updatedWallet.toJson());
      expect(secondSuccess.updatedHolding.toJson(),
          firstSuccess.updatedHolding.toJson());
      expect(secondSuccess.trade.toJson(), firstSuccess.trade.toJson());
      expect(secondSuccess.saleProceedsInr, firstSuccess.saleProceedsInr);
      expect(secondSuccess.realizedProfitLossInr,
          firstSuccess.realizedProfitLossInr);
    });
  });
}

VirtualWallet _wallet({double balanceInr = 1000000.0}) {
  return VirtualWallet(
    balanceInr: balanceInr,
    lockedInr: 0.0,
    initialBalanceInr: balanceInr,
  );
}

Holding _holding({
  String id = 'holding_1',
  String userId = 'user_1',
  String symbol = 'BTC',
  double quantity = 2.0,
  double averageEntryPriceInr = 4000000.0,
  double currentPriceInr = 4000000.0,
}) {
  return Holding(
    id: id,
    userId: userId,
    symbol: symbol,
    quantity: quantity,
    averageEntryPriceInr: averageEntryPriceInr,
    currentPriceInr: currentPriceInr,
  );
}

MarketTicker _ticker({
  String symbol = 'BTC',
  double priceInr = 5000000.0,
  required DateTime timestamp,
}) {
  final positivePrice = priceInr.isFinite && priceInr > 0 ? priceInr : 1.0;
  return MarketTicker(
    symbol: symbol,
    priceInr: priceInr,
    high24h: positivePrice * 1.1,
    low24h: positivePrice * 0.9,
    volume24h: 1000000.0,
    timestamp: timestamp,
  );
}
