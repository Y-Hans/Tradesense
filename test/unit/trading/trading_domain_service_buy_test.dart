import 'package:cryptoedu/features/trading/domain/buy_trade_result.dart';
import 'package:cryptoedu/features/trading/domain/trading_domain_service.dart';
import 'package:cryptoedu/features/trading/domain/trading_failure.dart';
import 'package:cryptoedu/shared/models/crypto_asset.dart';
import 'package:cryptoedu/shared/models/holding.dart';
import 'package:cryptoedu/shared/models/market_ticker.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TradingDomainService.calculateBuy', () {
    const service = TradingDomainService();
    final evaluatedAt = DateTime.utc(2026, 7, 28, 10);
    final executedAt = DateTime.utc(2026, 7, 28, 10, 0, 5);

    BuyTradeResult calculate({
      VirtualWallet? wallet,
      CryptoAsset? asset,
      MarketTicker? ticker,
      double buyAmountInr = 100000.0,
      Holding? existingHolding,
    }) {
      return service.calculateBuy(
        wallet: wallet ?? VirtualWallet.initial(),
        asset: asset ?? _asset(),
        ticker: ticker ?? _ticker(timestamp: evaluatedAt),
        buyAmountInr: buyAmountInr,
        existingHolding: existingHolding,
        executedAt: executedAt,
        evaluatedAt: evaluatedAt,
        tradeId: 'trade_1',
        userId: 'user_1',
        holdingId: 'holding_1',
        disciplineScoreAtTrade: 80,
        riskScoreAtTrade: 25,
      );
    }

    TradingFailureCode rejectedCode(BuyTradeResult result) {
      expect(result, isA<BuyTradeRejected>());
      return (result as BuyTradeRejected).failure.code;
    }

    test('successful first purchase creates holding, trade, and wallet update',
        () {
      final wallet = VirtualWallet.initial();
      final asset = _asset();
      final ticker = _ticker(timestamp: evaluatedAt);

      final result = calculate(wallet: wallet, asset: asset, ticker: ticker);

      expect(result, isA<BuyTradeSuccess>());
      final success = result as BuyTradeSuccess;
      expect(success.amountSpentInr, 100000.0);
      expect(success.executionPriceInr, 5000000.0);
      expect(success.purchasedQuantity, closeTo(0.02, 0.000000000000000001));
      expect(success.previousWalletBalanceInr, 10000000.0);
      expect(success.newWalletBalanceInr, 9900000.0);
      expect(success.updatedWallet.balanceInr, 9900000.0);
      expect(success.updatedHolding.symbol, 'BTC');
      expect(success.updatedHolding.quantity, closeTo(0.02, 0.0000000001));
      expect(success.updatedHolding.totalCostInr, closeTo(100000.0, 0.0001));
      expect(success.updatedHolding.averageEntryPriceInr, 5000000.0);
      expect(success.newCostBasisInr, 100000.0);
      expect(success.trade.id, 'trade_1');
      expect(success.trade.userId, 'user_1');
      expect(success.trade.symbol, 'BTC');
      expect(success.trade.side, TradeSide.buy);
      expect(success.trade.type, OrderType.market);
      expect(success.trade.quantity, closeTo(0.02, 0.0000000001));
      expect(success.trade.executionPriceInr, 5000000.0);
      expect(success.trade.totalAmountInr, 100000.0);
      expect(success.trade.timestamp, executedAt);
      expect(success.trade.disciplineScoreAtTrade, 80);
      expect(success.trade.riskScoreAtTrade, 25);

      expect(wallet.toJson(), VirtualWallet.initial().toJson());
      expect(asset.toJson(), _asset().toJson());
      expect(ticker.toJson(), _ticker(timestamp: evaluatedAt).toJson());
    });

    test('successful repeated purchase uses weighted average entry price', () {
      const wallet = VirtualWallet(
        balanceInr: 1000.0,
        lockedInr: 0.0,
        initialBalanceInr: 1000.0,
      );
      const existingHolding = Holding(
        id: 'holding_existing',
        userId: 'user_1',
        symbol: 'BTC',
        quantity: 1.0,
        averageEntryPriceInr: 100.0,
        currentPriceInr: 100.0,
      );

      final result = calculate(
        wallet: wallet,
        ticker: _ticker(priceInr: 150.0, timestamp: evaluatedAt),
        buyAmountInr: 300.0,
        existingHolding: existingHolding,
      );

      expect(result, isA<BuyTradeSuccess>());
      final success = result as BuyTradeSuccess;
      expect(success.purchasedQuantity, 2.0);
      expect(success.previousHoldingQuantity, 1.0);
      expect(success.newHoldingQuantity, 3.0);
      expect(success.previousCostBasisInr, 100.0);
      expect(success.newCostBasisInr, 400.0);
      expect(
          success.newAverageEntryPriceInr, closeTo(133.333333333333333, 1e-12));
      expect(success.newAverageEntryPriceInr, isNot(125.0));
      expect(success.updatedWallet.balanceInr, 700.0);
      expect(success.updatedHolding.id, 'holding_existing');
      expect(success.updatedHolding.quantity, 3.0);

      expect(existingHolding.quantity, 1.0);
      expect(existingHolding.averageEntryPriceInr, 100.0);
      expect(existingHolding.currentPriceInr, 100.0);
    });

    test('spending exactly the wallet balance succeeds and leaves zero cash',
        () {
      const wallet = VirtualWallet(
        balanceInr: 500.0,
        lockedInr: 0.0,
        initialBalanceInr: 500.0,
      );

      final result = calculate(
        wallet: wallet,
        ticker: _ticker(priceInr: 250.0, timestamp: evaluatedAt),
        buyAmountInr: 500.0,
      );

      expect(result, isA<BuyTradeSuccess>());
      final success = result as BuyTradeSuccess;
      expect(success.updatedWallet.balanceInr, 0.0);
      expect(success.updatedWallet.availableBalanceInr, 0.0);
      expect(success.updatedWallet.balanceInr.isNegative, isFalse);
    });

    test('insufficient funds rejects without producing a trade result', () {
      const wallet = VirtualWallet(
        balanceInr: 100.0,
        lockedInr: 0.0,
        initialBalanceInr: 100.0,
      );
      const holding = Holding(
        id: 'holding_existing',
        userId: 'user_1',
        symbol: 'BTC',
        quantity: 1.0,
        averageEntryPriceInr: 100.0,
        currentPriceInr: 100.0,
      );

      final result = calculate(
        wallet: wallet,
        buyAmountInr: 101.0,
        existingHolding: holding,
      );

      expect(rejectedCode(result), TradingFailureCode.insufficientFunds);
      expect(wallet.balanceInr, 100.0);
      expect(holding.quantity, 1.0);
    });

    test('zero and negative amounts are rejected', () {
      expect(rejectedCode(calculate(buyAmountInr: 0.0)),
          TradingFailureCode.invalidBuyAmount);
      expect(rejectedCode(calculate(buyAmountInr: -1.0)),
          TradingFailureCode.invalidBuyAmount);
    });

    test('non-finite amounts are rejected', () {
      expect(rejectedCode(calculate(buyAmountInr: double.nan)),
          TradingFailureCode.invalidBuyAmount);
      expect(rejectedCode(calculate(buyAmountInr: double.infinity)),
          TradingFailureCode.invalidBuyAmount);
    });

    test('zero, negative, and non-finite market prices are rejected', () {
      expect(
        rejectedCode(
          calculate(ticker: _ticker(priceInr: 0.0, timestamp: evaluatedAt)),
        ),
        TradingFailureCode.invalidMarketPrice,
      );
      expect(
        rejectedCode(
          calculate(ticker: _ticker(priceInr: -1.0, timestamp: evaluatedAt)),
        ),
        TradingFailureCode.invalidMarketPrice,
      );
      expect(
        rejectedCode(
          calculate(
            ticker: _ticker(priceInr: double.nan, timestamp: evaluatedAt),
          ),
        ),
        TradingFailureCode.invalidMarketPrice,
      );
    });

    test('stale ticker is rejected using caller supplied evaluation time', () {
      final staleTicker = _ticker(
        timestamp: evaluatedAt.subtract(const Duration(seconds: 31)),
      );

      expect(
        rejectedCode(calculate(ticker: staleTicker)),
        TradingFailureCode.staleTicker,
      );
    });

    test('mismatched ticker asset is rejected', () {
      expect(
        rejectedCode(
          calculate(ticker: _ticker(symbol: 'ETH', timestamp: evaluatedAt)),
        ),
        TradingFailureCode.mismatchedTicker,
      );
    });

    test('unsupported and invalid assets are rejected', () {
      expect(
        rejectedCode(calculate(asset: _asset(isSupportedV1: false))),
        TradingFailureCode.unsupportedAsset,
      );
      expect(
        rejectedCode(calculate(asset: _asset(symbol: ''))),
        TradingFailureCode.invalidAsset,
      );
      expect(
        rejectedCode(calculate(asset: _asset(symbol: 'DOGE'))),
        TradingFailureCode.unsupportedAsset,
      );
    });

    test('invalid existing holding states are rejected', () {
      expect(
        rejectedCode(
          calculate(
            existingHolding: _holding(quantity: -0.1),
          ),
        ),
        TradingFailureCode.invalidExistingHolding,
      );
      expect(
        rejectedCode(
          calculate(
            existingHolding: _holding(averageEntryPriceInr: -1.0),
          ),
        ),
        TradingFailureCode.invalidExistingHolding,
      );
      expect(
        rejectedCode(
          calculate(
            existingHolding: _holding(symbol: 'ETH'),
          ),
        ),
        TradingFailureCode.mismatchedHolding,
      );
    });

    test('precision-sensitive calculation follows Decimal boundary strategy',
        () {
      final result = calculate(
        buyAmountInr: 9876.54,
        ticker: _ticker(priceInr: 123456.789, timestamp: evaluatedAt),
      );

      expect(result, isA<BuyTradeSuccess>());
      final success = result as BuyTradeSuccess;
      final expectedQuantity =
          (Decimal.parse('9876.54') / Decimal.parse('123456.789'))
              .toDecimal(scaleOnInfinitePrecision: 18)
              .toDouble();

      expect(success.amountSpentInr, 9876.54);
      expect(success.purchasedQuantity, expectedQuantity);
      expect(success.updatedWallet.balanceInr, 9990123.46);
      expect(success.updatedHolding.totalCostInr, closeTo(9876.54, 0.000001));
    });

    test('same valid input produces equivalent results', () {
      final wallet = VirtualWallet.initial();
      final asset = _asset();
      final ticker = _ticker(timestamp: evaluatedAt);

      final first = calculate(wallet: wallet, asset: asset, ticker: ticker);
      final second = calculate(wallet: wallet, asset: asset, ticker: ticker);

      expect(first, isA<BuyTradeSuccess>());
      expect(second, isA<BuyTradeSuccess>());
      final firstSuccess = first as BuyTradeSuccess;
      final secondSuccess = second as BuyTradeSuccess;
      expect(secondSuccess.updatedWallet.toJson(),
          firstSuccess.updatedWallet.toJson());
      expect(secondSuccess.updatedHolding.toJson(),
          firstSuccess.updatedHolding.toJson());
      expect(secondSuccess.trade.toJson(), firstSuccess.trade.toJson());
      expect(secondSuccess.amountSpentInr, firstSuccess.amountSpentInr);
      expect(secondSuccess.purchasedQuantity, firstSuccess.purchasedQuantity);
    });

    test('calculation has no side effects on input objects', () {
      const wallet = VirtualWallet(
        balanceInr: 1000.0,
        lockedInr: 100.0,
        initialBalanceInr: 1000.0,
      );
      final asset = _asset(currentPriceInr: 150.0);
      final ticker = _ticker(priceInr: 150.0, timestamp: evaluatedAt);
      final holding = _holding();
      final walletBefore = wallet.toJson();
      final assetBefore = asset.toJson();
      final tickerBefore = ticker.toJson();
      final holdingBefore = holding.toJson();

      final result = calculate(
        wallet: wallet,
        asset: asset,
        ticker: ticker,
        buyAmountInr: 300.0,
        existingHolding: holding,
      );

      expect(result, isA<BuyTradeSuccess>());
      expect(wallet.toJson(), walletBefore);
      expect(asset.toJson(), assetBefore);
      expect(ticker.toJson(), tickerBefore);
      expect(holding.toJson(), holdingBefore);
    });
  });
}

CryptoAsset _asset({
  String symbol = 'BTC',
  String name = 'Bitcoin',
  double currentPriceInr = 5000000.0,
  bool isSupportedV1 = true,
}) {
  return CryptoAsset(
    symbol: symbol,
    name: name,
    iconUrl: 'assets/icons/btc.png',
    currentPriceInr: currentPriceInr,
    change24hPercent: 1.0,
    isSupportedV1: isSupportedV1,
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

Holding _holding({
  String symbol = 'BTC',
  double quantity = 1.0,
  double averageEntryPriceInr = 100.0,
  double currentPriceInr = 100.0,
}) {
  return Holding(
    id: 'holding_existing',
    userId: 'user_1',
    symbol: symbol,
    quantity: quantity,
    averageEntryPriceInr: averageEntryPriceInr,
    currentPriceInr: currentPriceInr,
  );
}
