import 'package:cryptoedu/features/portfolio/domain/portfolio_engine.dart';
import 'package:cryptoedu/features/portfolio/domain/portfolio_engine_result.dart';
import 'package:cryptoedu/features/trading/domain/trading_failure.dart';
import 'package:cryptoedu/shared/models/holding.dart';
import 'package:cryptoedu/shared/models/market_ticker.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PortfolioEngine.calculate', () {
    const engine = PortfolioEngine();
    final evaluatedAt = DateTime.utc(2026, 7, 29, 12);

    PortfolioEngineResult calculate({
      VirtualWallet wallet = const VirtualWallet(
        balanceInr: 1000.0,
        lockedInr: 0.0,
        initialBalanceInr: 1000.0,
      ),
      List<Holding> holdings = const [],
      List<MarketTicker> tickers = const [],
      List<Trade> trades = const [],
    }) {
      return engine.calculate(
        wallet: wallet,
        holdings: holdings,
        tickers: tickers,
        trades: trades,
        evaluatedAt: evaluatedAt,
      );
    }

    PortfolioSnapshot snapshot(PortfolioEngineResult result) {
      expect(result, isA<PortfolioEngineSuccess>());
      return (result as PortfolioEngineSuccess).snapshot;
    }

    TradingFailureCode rejectedCode(PortfolioEngineResult result) {
      expect(result, isA<PortfolioEngineRejected>());
      return (result as PortfolioEngineRejected).failure.code;
    }

    test('empty portfolio returns wallet value and all-cash allocation', () {
      final result = calculate();

      final portfolio = snapshot(result);
      expect(portfolio.wallet.cashBalanceInr, 1000.0);
      expect(portfolio.totals.cashBalanceInr, 1000.0);
      expect(portfolio.totals.cryptoValueInr, 0.0);
      expect(portfolio.totals.portfolioValueInr, 1000.0);
      expect(portfolio.totals.investedAmountInr, 0.0);
      expect(portfolio.totals.totalUnrealizedProfitLossInr, 0.0);
      expect(portfolio.totals.totalRealizedProfitLossInr, 0.0);
      expect(portfolio.totals.overallProfitLossInr, 0.0);
      expect(portfolio.totals.overallReturnPercent, 0.0);
      expect(portfolio.totals.cashAllocationPercent, 100.0);
      expect(portfolio.totals.cryptoAllocationPercent, 0.0);
      expect(portfolio.totals.numberOfAssets, 0);
      expect(portfolio.totals.numberOfOpenHoldings, 0);
      expect(portfolio.assetSummaries, isEmpty);
      expect(portfolio.allocation.assets, isEmpty);
      expect(portfolio.performance.bestPerformingAsset, isNull);
      expect(portfolio.performance.worstPerformingAsset, isNull);
      expect(portfolio.evaluatedAt, evaluatedAt);
    });

    test('wallet only with locked cash uses total cash balance for allocation',
        () {
      final result = calculate(
        wallet: const VirtualWallet(
          balanceInr: 900.0,
          lockedInr: 100.0,
          initialBalanceInr: 1000.0,
        ),
      );

      final portfolio = snapshot(result);
      expect(portfolio.wallet.cashBalanceInr, 900.0);
      expect(portfolio.wallet.lockedBalanceInr, 100.0);
      expect(portfolio.wallet.availableBalanceInr, 800.0);
      expect(portfolio.totals.portfolioValueInr, 900.0);
      expect(portfolio.totals.cashAllocationPercent, 100.0);
    });

    test('one profitable asset calculates value, unrealized P&L, and return',
        () {
      final result = calculate(
        holdings: [_holding(quantity: 2.0, averageEntryPriceInr: 100.0)],
        tickers: [_ticker(priceInr: 150.0, timestamp: evaluatedAt)],
      );

      final portfolio = snapshot(result);
      final asset = portfolio.assetSummaries.single;
      expect(asset.assetSymbol, 'BTC');
      expect(asset.quantity, 2.0);
      expect(asset.averageEntryPriceInr, 100.0);
      expect(asset.currentPriceInr, 150.0);
      expect(asset.currentValueInr, 300.0);
      expect(asset.costBasisInr, 200.0);
      expect(asset.unrealizedProfitLossInr, 100.0);
      expect(asset.returnPercent, 50.0);
      expect(asset.allocationPercent, closeTo(23.0769, 0.0001));
      expect(portfolio.totals.cryptoValueInr, 300.0);
      expect(portfolio.totals.portfolioValueInr, 1300.0);
      expect(portfolio.totals.totalUnrealizedProfitLossInr, 100.0);
      expect(portfolio.performance.bestPerformingAsset?.assetSymbol, 'BTC');
    });

    test('one losing asset calculates negative unrealized P&L', () {
      final result = calculate(
        holdings: [_holding(quantity: 2.0, averageEntryPriceInr: 100.0)],
        tickers: [_ticker(priceInr: 80.0, timestamp: evaluatedAt)],
      );

      final asset = snapshot(result).assetSummaries.single;
      expect(asset.currentValueInr, 160.0);
      expect(asset.unrealizedProfitLossInr, -40.0);
      expect(asset.returnPercent, -20.0);
    });

    test('multiple assets cover mixed gains and losses', () {
      final result = calculate(
        wallet: _wallet(balanceInr: 500.0),
        holdings: [
          _holding(symbol: 'BTC', quantity: 1.0, averageEntryPriceInr: 100.0),
          _holding(
            id: 'holding_eth',
            symbol: 'ETH',
            quantity: 2.0,
            averageEntryPriceInr: 100.0,
          ),
          _holding(
            id: 'holding_sol',
            symbol: 'SOL',
            quantity: 1.0,
            averageEntryPriceInr: 50.0,
          ),
        ],
        tickers: [
          _ticker(symbol: 'BTC', priceInr: 150.0, timestamp: evaluatedAt),
          _ticker(symbol: 'ETH', priceInr: 90.0, timestamp: evaluatedAt),
          _ticker(symbol: 'SOL', priceInr: 50.0, timestamp: evaluatedAt),
        ],
      );

      final portfolio = snapshot(result);
      expect(portfolio.totals.cryptoValueInr, 380.0);
      expect(portfolio.totals.portfolioValueInr, 880.0);
      expect(portfolio.totals.totalCostBasisInr, 350.0);
      expect(portfolio.totals.totalUnrealizedProfitLossInr, 30.0);
      expect(portfolio.totals.overallProfitLossInr, 30.0);
      expect(portfolio.totals.overallReturnPercent, closeTo(8.5714, 0.0001));
      expect(portfolio.totals.numberOfAssets, 3);
      expect(portfolio.totals.numberOfOpenHoldings, 3);
      expect(portfolio.performance.bestPerformingAsset?.assetSymbol, 'BTC');
      expect(portfolio.performance.worstPerformingAsset?.assetSymbol, 'ETH');
      expect(portfolio.performance.largestPosition?.assetSymbol, 'ETH');
      expect(portfolio.performance.smallestPosition?.assetSymbol, 'SOL');
      expect(portfolio.performance.highestAllocation?.assetSymbol, 'ETH');
      expect(portfolio.performance.lowestAllocation?.assetSymbol, 'SOL');
    });

    test('cash, crypto, and asset allocations sum approximately to 100%', () {
      final result = calculate(
        wallet: _wallet(balanceInr: 500.0),
        holdings: [
          _holding(symbol: 'BTC', quantity: 10.0, averageEntryPriceInr: 100.0),
          _holding(
            id: 'holding_eth',
            symbol: 'ETH',
            quantity: 5.0,
            averageEntryPriceInr: 100.0,
          ),
        ],
        tickers: [
          _ticker(symbol: 'BTC', priceInr: 100.0, timestamp: evaluatedAt),
          _ticker(symbol: 'ETH', priceInr: 100.0, timestamp: evaluatedAt),
        ],
      );

      final portfolio = snapshot(result);
      final assetAllocationTotal = portfolio.allocation.assets.fold(
        0.0,
        (sum, allocation) => sum + allocation.allocationPercent,
      );
      expect(portfolio.totals.cashAllocationPercent, 25.0);
      expect(portfolio.totals.cryptoAllocationPercent, 75.0);
      expect(assetAllocationTotal, closeTo(75.0, 0.0001));
      expect(
        portfolio.totals.cashAllocationPercent + assetAllocationTotal,
        closeTo(100.0, 0.0001),
      );
    });

    test('realized P&L is replayed from supplied trade history', () {
      final result = calculate(
        wallet: _wallet(balanceInr: 1040.0),
        holdings: [_holding(quantity: 1.0, averageEntryPriceInr: 100.0)],
        tickers: [_ticker(priceInr: 110.0, timestamp: evaluatedAt)],
        trades: [
          _trade(
            id: 'buy_1',
            side: TradeSide.buy,
            quantity: 2.0,
            executionPriceInr: 100.0,
            totalAmountInr: 200.0,
          ),
          _trade(
            id: 'sell_1',
            side: TradeSide.sell,
            quantity: 0.5,
            executionPriceInr: 130.0,
            totalAmountInr: 65.0,
          ),
          _trade(
            id: 'sell_2',
            side: TradeSide.sell,
            quantity: 0.5,
            executionPriceInr: 80.0,
            totalAmountInr: 40.0,
          ),
        ],
      );

      final portfolio = snapshot(result);
      expect(portfolio.totals.totalRealizedProfitLossInr, 5.0);
      expect(portfolio.totals.totalUnrealizedProfitLossInr, 10.0);
      expect(portfolio.totals.overallProfitLossInr, 15.0);
    });

    test('zero market movement produces zero unrealized P&L and return', () {
      final result = calculate(
        holdings: [_holding(quantity: 2.0, averageEntryPriceInr: 100.0)],
        tickers: [_ticker(priceInr: 100.0, timestamp: evaluatedAt)],
      );

      final asset = snapshot(result).assetSummaries.single;
      expect(asset.unrealizedProfitLossInr, 0.0);
      expect(asset.returnPercent, 0.0);
    });

    test('decimal precision follows Decimal plus paise boundary rounding', () {
      final result = calculate(
        wallet: _wallet(balanceInr: 10.0),
        holdings: [
          _holding(quantity: 0.3, averageEntryPriceInr: 33.3333),
        ],
        tickers: [_ticker(priceInr: 66.6667, timestamp: evaluatedAt)],
      );

      final asset = snapshot(result).assetSummaries.single;
      expect(asset.costBasisInr, 10.0);
      expect(asset.currentValueInr, 20.0);
      expect(asset.unrealizedProfitLossInr, 10.0);
      expect(asset.returnPercent, closeTo(100.0002, 0.0001));
    });

    test('same valid input produces equivalent snapshots', () {
      final wallet = _wallet(balanceInr: 500.0);
      final holdings = [_holding(quantity: 2.0, averageEntryPriceInr: 100.0)];
      final tickers = [_ticker(priceInr: 125.0, timestamp: evaluatedAt)];

      final first = snapshot(
        calculate(wallet: wallet, holdings: holdings, tickers: tickers),
      );
      final second = snapshot(
        calculate(wallet: wallet, holdings: holdings, tickers: tickers),
      );

      expect(second.totals.portfolioValueInr, first.totals.portfolioValueInr);
      expect(
        second.totals.totalUnrealizedProfitLossInr,
        first.totals.totalUnrealizedProfitLossInr,
      );
      expect(second.assetSummaries.single.currentValueInr,
          first.assetSummaries.single.currentValueInr);
      expect(second.performance.bestPerformingAsset?.assetSymbol,
          first.performance.bestPerformingAsset?.assetSymbol);
    });

    test('calculation does not mutate input objects and output lists are fixed',
        () {
      final wallet = _wallet(balanceInr: 500.0);
      final holding = _holding(quantity: 2.0, averageEntryPriceInr: 100.0);
      final ticker = _ticker(priceInr: 125.0, timestamp: evaluatedAt);
      final walletBefore = wallet.toJson();
      final holdingBefore = holding.toJson();
      final tickerBefore = ticker.toJson();

      final portfolio = snapshot(
        calculate(wallet: wallet, holdings: [holding], tickers: [ticker]),
      );

      expect(wallet.toJson(), walletBefore);
      expect(holding.toJson(), holdingBefore);
      expect(ticker.toJson(), tickerBefore);
      expect(
        () => portfolio.assetSummaries.add(portfolio.assetSummaries.single),
        throwsUnsupportedError,
      );
      expect(
        () =>
            portfolio.allocation.assets.add(portfolio.allocation.assets.single),
        throwsUnsupportedError,
      );
    });

    test('invalid wallet state is rejected', () {
      final result = calculate(
        wallet: const VirtualWallet(
          balanceInr: -1.0,
          lockedInr: 0.0,
          initialBalanceInr: 1000.0,
        ),
      );

      expect(rejectedCode(result), TradingFailureCode.invalidWallet);
    });

    test('invalid holdings are rejected', () {
      expect(
        rejectedCode(
          calculate(
            holdings: [_holding(quantity: -0.1)],
            tickers: [_ticker(timestamp: evaluatedAt)],
          ),
        ),
        TradingFailureCode.invalidExistingHolding,
      );
      expect(
        rejectedCode(
          calculate(
            holdings: [
              _holding(symbol: 'BTC'),
              _holding(id: 'holding_btc_2', symbol: 'btc'),
            ],
            tickers: [_ticker(timestamp: evaluatedAt)],
          ),
        ),
        TradingFailureCode.invalidExistingHolding,
      );
    });

    test('negative, duplicate, stale, and missing tickers are rejected', () {
      expect(
        rejectedCode(
          calculate(
            holdings: [_holding()],
            tickers: [_ticker(priceInr: -1.0, timestamp: evaluatedAt)],
          ),
        ),
        TradingFailureCode.invalidMarketPrice,
      );
      expect(
        rejectedCode(
          calculate(
            holdings: [_holding()],
            tickers: [
              _ticker(symbol: 'BTC', timestamp: evaluatedAt),
              _ticker(symbol: 'btc', timestamp: evaluatedAt),
            ],
          ),
        ),
        TradingFailureCode.invalidMarketPrice,
      );
      expect(
        rejectedCode(
          calculate(
            holdings: [_holding()],
            tickers: [
              _ticker(
                timestamp: evaluatedAt.subtract(const Duration(seconds: 31)),
              ),
            ],
          ),
        ),
        TradingFailureCode.staleTicker,
      );
      expect(
        rejectedCode(
          calculate(
            holdings: [_holding(symbol: 'BTC')],
            tickers: [_ticker(symbol: 'ETH', timestamp: evaluatedAt)],
          ),
        ),
        TradingFailureCode.invalidMarketPrice,
      );
    });

    test('invalid trade history is rejected', () {
      expect(
        rejectedCode(calculate(trades: [_trade(id: '')])),
        TradingFailureCode.invalidTradeMetadata,
      );
      expect(
        rejectedCode(
          calculate(
            trades: [
              _trade(
                side: TradeSide.sell,
                quantity: 1.0,
                totalAmountInr: 100.0,
              ),
            ],
          ),
        ),
        TradingFailureCode.insufficientHoldings,
      );
    });
  });
}

VirtualWallet _wallet({double balanceInr = 1000.0}) {
  return VirtualWallet(
    balanceInr: balanceInr,
    lockedInr: 0.0,
    initialBalanceInr: 1000.0,
  );
}

Holding _holding({
  String id = 'holding_btc',
  String userId = 'user_1',
  String symbol = 'BTC',
  double quantity = 1.0,
  double averageEntryPriceInr = 100.0,
  double currentPriceInr = 100.0,
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
  double priceInr = 100.0,
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

Trade _trade({
  String id = 'trade_1',
  String userId = 'user_1',
  String symbol = 'BTC',
  TradeSide side = TradeSide.buy,
  double quantity = 1.0,
  double executionPriceInr = 100.0,
  double totalAmountInr = 100.0,
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
    timestamp: timestamp ?? DateTime.utc(2026, 7, 29, 10),
    disciplineScoreAtTrade: 80,
    riskScoreAtTrade: 25,
  );
}
