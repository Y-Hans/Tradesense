import 'package:cryptoedu/features/trading/application/execute_sell_result.dart';
import 'package:cryptoedu/features/trading/application/execute_sell_use_case.dart';
import 'package:cryptoedu/features/trading/domain/stop_loss_evaluation_result.dart';
import 'package:cryptoedu/features/trading/domain/trading_domain_service.dart';
import 'package:cryptoedu/features/trading/domain/trading_failure.dart';
import 'package:cryptoedu/shared/models/holding.dart';
import 'package:cryptoedu/shared/models/market_ticker.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/execute_buy_fakes.dart';

void main() {
  group('ExecuteSellUseCase', () {
    final evaluatedAt = DateTime.utc(2026, 7, 30, 10);

    test('successful manual SELL loads dynamic state and commits atomically',
        () async {
      final harness = _Harness(evaluatedAt);

      final result = await harness.execute();

      expect(result, isA<ExecuteSellSuccess>());
      final success = result as ExecuteSellSuccess;
      expect(harness.walletRepository.lookupCount, 1);
      expect(harness.holdingRepository.lookupCount, 1);
      expect(harness.marketProvider.tickerLookupCount, 1);
      expect(harness.transactionRepository.commitAttempts, 1);
      expect(harness.transactionRepository.successfulCommits, 1);
      expect(success.sellReason, ExecuteSellRequest.manualReason);
      expect(success.sourceStopLossOrderId, isNull);
      expect(success.domainDetails.saleProceedsInr, 2500000.0);
      expect(success.domainDetails.soldQuantity, 0.5);
      expect(success.domainDetails.realizedProfitLossInr, 500000.0);
      expect(success.updatedWallet.balanceInr, 3500000.0);
      expect(success.updatedHolding.quantity, 1.5);
      expect(success.updatedHolding.averageEntryPriceInr, 4000000.0);
      expect(success.trade.id, 'trade_1');
      expect(success.trade.userId, 'user_1');
      expect(success.trade.symbol, 'BTC');
      expect(success.trade.side, TradeSide.sell);
      expect(success.executionTicker.priceInr, 5000000.0);
      expect(success.commitConfirmation.confirmationId, 'commit_1');
      expect(
        harness.walletRepository.wallets['user_1']!.wallet.toJson(),
        success.updatedWallet.toJson(),
      );
      expect(
        harness.holdingRepository.holdings['user_1:BTC']!.toJson(),
        success.updatedHolding.toJson(),
      );
      expect(
        harness.transactionRepository.trades.single.toJson(),
        success.trade.toJson(),
      );
    });

    test('successful stop-loss SELL uses generated execution request metadata',
        () async {
      final harness = _Harness(evaluatedAt);
      final stopLossRequest = _stopLossRequest(evaluatedAt: evaluatedAt);

      final result = await harness.executeStopLoss(stopLossRequest);

      expect(result, isA<ExecuteSellSuccess>());
      final success = result as ExecuteSellSuccess;
      expect(success.sellReason, SellExecutionRequest.stopLossReason);
      expect(success.sourceStopLossOrderId, 'sl_1');
      expect(success.domainDetails.soldQuantity, 0.25);
      expect(success.updatedWallet.balanceInr, 2250000.0);
      expect(success.updatedHolding.quantity, 1.75);
      expect(harness.transactionRepository.lastSellReason,
          SellExecutionRequest.stopLossReason);
      expect(harness.transactionRepository.lastSourceStopLossOrderId, 'sl_1');
      expect(
          harness.transactionRepository.trades.single.timestamp, evaluatedAt);
    });

    test('wallet not found returns typed failure and short-circuits', () async {
      final harness = _Harness(evaluatedAt, addWallet: false);

      final result = await harness.execute();

      expect(_applicationCode(result), ExecuteSellFailureCode.walletNotFound);
      expect(harness.walletRepository.lookupCount, 1);
      expect(harness.holdingRepository.lookupCount, 0);
      expect(harness.marketProvider.tickerLookupCount, 0);
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('holding not found returns typed failure before market lookup',
        () async {
      final harness = _Harness(evaluatedAt, addHolding: false);

      final result = await harness.execute();

      expect(_applicationCode(result), ExecuteSellFailureCode.holdingNotFound);
      expect(harness.walletRepository.lookupCount, 1);
      expect(harness.holdingRepository.lookupCount, 1);
      expect(harness.marketProvider.tickerLookupCount, 0);
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('ticker unavailable returns typed failure without state changes',
        () async {
      final harness = _Harness(evaluatedAt);
      harness.marketProvider.failUnavailable = true;
      final walletBefore =
          harness.walletRepository.wallets['user_1']!.wallet.toJson();
      final holdingBefore =
          harness.holdingRepository.holdings['user_1:BTC']!.toJson();

      final result = await harness.execute();

      expect(
        _applicationCode(result),
        ExecuteSellFailureCode.marketTickerUnavailable,
      );
      expect(harness.transactionRepository.commitAttempts, 0);
      expect(harness.walletRepository.wallets['user_1']!.wallet.toJson(),
          walletBefore);
      expect(harness.holdingRepository.holdings['user_1:BTC']!.toJson(),
          holdingBefore);
    });

    test('wallet repository failure returns typed application failure',
        () async {
      final harness = _Harness(evaluatedAt);
      harness.walletRepository.failLookup = true;

      final result = await harness.execute();

      expect(
        _applicationCode(result),
        ExecuteSellFailureCode.walletRepositoryFailure,
      );
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('oversell preserves the typed domain rejection', () async {
      final harness = _Harness(evaluatedAt);

      final result = await harness.execute(quantity: 2.1);

      expect(_domainCode(result), TradingFailureCode.insufficientHoldings);
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('stale ticker preserves the typed domain rejection', () async {
      final harness = _Harness(evaluatedAt);
      harness.marketProvider.putTicker(
        _ticker(
          timestamp: evaluatedAt.subtract(const Duration(seconds: 31)),
        ),
      );

      final result = await harness.execute();

      expect(_domainCode(result), TradingFailureCode.staleTicker);
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('persistence failure never reports success or mutates fake storage',
        () async {
      final harness = _Harness(evaluatedAt);
      harness.transactionRepository.mode = FakeCommitMode.persistenceFailure;
      final walletBefore =
          harness.walletRepository.wallets['user_1']!.wallet.toJson();
      final holdingBefore =
          harness.holdingRepository.holdings['user_1:BTC']!.toJson();

      final result = await harness.execute();

      expect(
        _applicationCode(result),
        ExecuteSellFailureCode.transactionPersistenceFailure,
      );
      expect(harness.transactionRepository.commitAttempts, 1);
      expect(harness.transactionRepository.successfulCommits, 0);
      expect(harness.transactionRepository.trades, isEmpty);
      expect(harness.walletRepository.wallets['user_1']!.wallet.toJson(),
          walletBefore);
      expect(harness.holdingRepository.holdings['user_1:BTC']!.toJson(),
          holdingBefore);
    });

    test('concurrency conflict returns typed failure with no partial state',
        () async {
      final harness = _Harness(evaluatedAt);
      harness.transactionRepository.beforeValidation = () {
        harness.holdingRepository.put(_holding(quantity: 1.9));
      };

      final result = await harness.execute();

      expect(
          _applicationCode(result), ExecuteSellFailureCode.concurrencyConflict);
      expect(harness.transactionRepository.commitAttempts, 1);
      expect(harness.transactionRepository.successfulCommits, 0);
      expect(harness.transactionRepository.trades, isEmpty);
      expect(
        harness.holdingRepository.holdings['user_1:BTC']!.quantity,
        1.9,
      );
    });

    test('repository update ordering persists wallet, holding, and trade',
        () async {
      final harness = _Harness(evaluatedAt);

      final result = await harness.execute();

      expect(result, isA<ExecuteSellSuccess>());
      final success = result as ExecuteSellSuccess;
      expect(harness.transactionRepository.commitSteps,
          ['wallet', 'holding', 'trade']);
      expect(
        harness.walletRepository.wallets['user_1']!.wallet.toJson(),
        success.updatedWallet.toJson(),
      );
      expect(
        harness.holdingRepository.holdings['user_1:BTC']!.toJson(),
        success.updatedHolding.toJson(),
      );
      expect(
        harness.transactionRepository.trades.single.toJson(),
        success.trade.toJson(),
      );
    });

    test('input request and stop-loss execution request remain immutable',
        () async {
      final harness = _Harness(evaluatedAt);
      final stopLossRequest = _stopLossRequest(evaluatedAt: evaluatedAt);
      final request = ExecuteSellRequest.fromStopLoss(
        userId: 'user_1',
        executionRequest: stopLossRequest,
        disciplineScoreAtTrade: 80,
        riskScoreAtTrade: 25,
      );

      await harness.useCase.execute(request);

      expect(request.userId, 'user_1');
      expect(request.assetSymbol, 'BTC');
      expect(request.quantity, 0.25);
      expect(request.sellReason, SellExecutionRequest.stopLossReason);
      expect(stopLossRequest.orderId, 'sl_1');
      expect(stopLossRequest.assetSymbol, 'BTC');
      expect(stopLossRequest.quantity, 0.25);
      expect(stopLossRequest.marketPriceInr, 5000000.0);
      expect(stopLossRequest.triggerPriceInr, 5100000.0);
      expect(stopLossRequest.evaluatedAt, evaluatedAt);
    });

    test('identical repositories, fake clock, and fake IDs are deterministic',
        () async {
      final firstHarness = _Harness(evaluatedAt);
      final secondHarness = _Harness(evaluatedAt);

      final first = await firstHarness.execute();
      final second = await secondHarness.execute();

      expect(first, isA<ExecuteSellSuccess>());
      expect(second, isA<ExecuteSellSuccess>());
      final firstSuccess = first as ExecuteSellSuccess;
      final secondSuccess = second as ExecuteSellSuccess;
      expect(secondSuccess.updatedWallet.toJson(),
          firstSuccess.updatedWallet.toJson());
      expect(secondSuccess.updatedHolding.toJson(),
          firstSuccess.updatedHolding.toJson());
      expect(secondSuccess.trade.toJson(), firstSuccess.trade.toJson());
      expect(secondSuccess.commitConfirmation.confirmationId,
          firstSuccess.commitConfirmation.confirmationId);
    });
  });
}

class _Harness {
  final FakeExecuteBuyWalletRepository walletRepository;
  final FakeExecuteBuyHoldingRepository holdingRepository;
  final FakeMarketProvider marketProvider;
  late final FakeTradingTransactionRepository transactionRepository;
  final FakeExecuteBuyClock clock;
  final FakeExecuteBuyIdGenerator idGenerator;
  late final ExecuteSellUseCase useCase;

  _Harness(
    DateTime evaluatedAt, {
    VirtualWallet wallet = const VirtualWallet(
      balanceInr: 1000000.0,
      lockedInr: 0.0,
    ),
    Holding? holding,
    double tickerPriceInr = 5000000.0,
    bool addWallet = true,
    bool addHolding = true,
  })  : walletRepository = FakeExecuteBuyWalletRepository(),
        holdingRepository = FakeExecuteBuyHoldingRepository(),
        marketProvider = FakeMarketProvider(),
        clock = FakeExecuteBuyClock(evaluatedAt),
        idGenerator = FakeExecuteBuyIdGenerator() {
    if (addWallet) {
      walletRepository.put(userId: 'user_1', wallet: wallet);
    }
    if (addHolding) {
      holdingRepository.put(holding ?? _holding());
    }
    marketProvider.putTicker(
      _ticker(priceInr: tickerPriceInr, timestamp: evaluatedAt),
    );
    transactionRepository = FakeTradingTransactionRepository(
      walletRepository: walletRepository,
      holdingRepository: holdingRepository,
    );
    useCase = ExecuteSellUseCase(
      walletRepository: walletRepository,
      holdingRepository: holdingRepository,
      marketProvider: marketProvider,
      transactionRepository: transactionRepository,
      tradingDomainService: const TradingDomainService(),
      clock: clock,
      idGenerator: idGenerator,
    );
  }

  Future<ExecuteSellResult> execute({
    double quantity = 0.5,
    String assetSymbol = 'BTC',
  }) {
    return useCase.execute(
      ExecuteSellRequest(
        userId: 'user_1',
        assetSymbol: assetSymbol,
        quantity: quantity,
        disciplineScoreAtTrade: 80,
        riskScoreAtTrade: 25,
      ),
    );
  }

  Future<ExecuteSellResult> executeStopLoss(
    SellExecutionRequest executionRequest,
  ) {
    return useCase.execute(
      ExecuteSellRequest.fromStopLoss(
        userId: 'user_1',
        executionRequest: executionRequest,
        disciplineScoreAtTrade: 80,
        riskScoreAtTrade: 25,
      ),
    );
  }
}

ExecuteSellFailureCode _applicationCode(ExecuteSellResult result) {
  expect(result, isA<ExecuteSellApplicationFailed>());
  return (result as ExecuteSellApplicationFailed).failure.code;
}

TradingFailureCode _domainCode(ExecuteSellResult result) {
  expect(result, isA<ExecuteSellDomainRejected>());
  return (result as ExecuteSellDomainRejected).failure.code;
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
  return MarketTicker(
    symbol: symbol,
    priceInr: priceInr,
    high24h: priceInr * 1.1,
    low24h: priceInr * 0.9,
    volume24h: 1000000.0,
    timestamp: timestamp,
  );
}

SellExecutionRequest _stopLossRequest({
  required DateTime evaluatedAt,
}) {
  return SellExecutionRequest(
    orderId: 'sl_1',
    assetSymbol: 'BTC',
    quantity: 0.25,
    marketPriceInr: 5000000.0,
    triggerPriceInr: 5100000.0,
    estimatedProceedsInr: 1250000.0,
    evaluatedAt: evaluatedAt,
  );
}
