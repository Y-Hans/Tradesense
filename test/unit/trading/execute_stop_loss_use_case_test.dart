import 'package:cryptoedu/features/trading/application/execute_sell_result.dart';
import 'package:cryptoedu/features/trading/application/execute_sell_use_case.dart';
import 'package:cryptoedu/features/trading/application/execute_stop_loss_result.dart';
import 'package:cryptoedu/features/trading/application/execute_stop_loss_use_case.dart';
import 'package:cryptoedu/features/trading/domain/stop_loss_engine.dart';
import 'package:cryptoedu/features/trading/domain/stop_loss_evaluation_result.dart';
import 'package:cryptoedu/features/trading/domain/trading_domain_service.dart';
import 'package:cryptoedu/features/trading/domain/trading_failure.dart';
import 'package:cryptoedu/shared/models/holding.dart';
import 'package:cryptoedu/shared/models/market_ticker.dart';
import 'package:cryptoedu/shared/models/stop_loss_order.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/execute_buy_fakes.dart';
import 'fakes/execute_stop_loss_fakes.dart';

void main() {
  group('ExecuteStopLossUseCase', () {
    final evaluatedAt = DateTime.utc(2026, 7, 30, 10);

    test('successful execution loads state, evaluates, and aggregates counts',
        () async {
      final harness = _Harness(evaluatedAt);
      harness.addStopLossOrder(_order(triggerPriceInr: 5100000.0));

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteStopLossSuccess>());
      final success = result as ExecuteStopLossSuccess;
      expect(harness.callLog, [
        'wallet:user_1',
        'holdings:user_1',
        'orders:user_1',
        'ticker:BTC',
        'wallet:user_1',
        'ticker:BTC',
      ]);
      expect(harness.transactionRepository.commitAttempts, 1);
      expect(success.evaluation.evaluatedAt, evaluatedAt);
      expect(success.evaluatedOrderCount, 1);
      expect(success.triggeredOrderCount, 1);
      expect(success.executedSellCount, 1);
      expect(success.skippedOrderCount, 0);
      expect(success.executedSells.single.stopLossOrderId, 'sl_1');
      expect(success.executedSells.single.sellResult.sellReason,
          SellExecutionRequest.stopLossReason);
      expect(success.executedSells.single.sellResult.sourceStopLossOrderId,
          'sl_1');
    });

    test('no stop-loss orders succeeds without market or sell execution',
        () async {
      final harness = _Harness(evaluatedAt);

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteStopLossSuccess>());
      final success = result as ExecuteStopLossSuccess;
      expect(success.evaluatedOrderCount, 0);
      expect(success.triggeredOrderCount, 0);
      expect(success.executedSellCount, 0);
      expect(success.skippedOrderCount, 0);
      expect(harness.marketProvider.requestedSymbols, isEmpty);
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('no holdings succeeds gracefully with rejected skipped orders',
        () async {
      final harness = _Harness(evaluatedAt, addHolding: false);
      harness.addStopLossOrder(_order(triggerPriceInr: 5100000.0));

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteStopLossSuccess>());
      final success = result as ExecuteStopLossSuccess;
      expect(success.evaluatedOrderCount, 1);
      expect(success.triggeredOrderCount, 0);
      expect(success.executedSellCount, 0);
      expect(success.rejectedOrderCount, 1);
      expect(success.skippedOrderCount, 1);
      expect(
        success.evaluation.rejectedOrders.single.failure.code,
        TradingFailureCode.missingHolding,
      );
      expect(harness.marketProvider.requestedSymbols, isEmpty);
    });

    test('no triggered orders succeeds with pending count only', () async {
      final harness = _Harness(evaluatedAt);
      harness.addStopLossOrder(_order(triggerPriceInr: 4900000.0));

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteStopLossSuccess>());
      final success = result as ExecuteStopLossSuccess;
      expect(success.evaluatedOrderCount, 1);
      expect(success.triggeredOrderCount, 0);
      expect(success.executedSellCount, 0);
      expect(success.pendingOrderCount, 1);
      expect(success.skippedOrderCount, 1);
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('one triggered sell delegates through ExecuteSellUseCase once',
        () async {
      final harness = _Harness(evaluatedAt);
      harness.addStopLossOrder(_order(triggerPriceInr: 5100000.0));

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteStopLossSuccess>());
      expect(harness.transactionRepository.commitAttempts, 1);
      expect(harness.transactionRepository.successfulCommits, 1);
      expect(harness.idGenerator.tradeIdCount, 1);
      expect(harness.transactionRepository.trades.single.id, 'trade_1');
      expect(harness.transactionRepository.lastSourceStopLossOrderId, 'sl_1');
    });

    test('multiple triggered sells execute in deterministic symbol order',
        () async {
      final harness = _Harness(
        evaluatedAt,
        tradeIds: ['trade_btc', 'trade_eth'],
      );
      harness.addHolding(_holding(
        id: 'holding_eth',
        symbol: 'ETH',
        quantity: 3.0,
        averageEntryPriceInr: 200000.0,
        currentPriceInr: 200000.0,
      ));
      harness.addTicker(_ticker(
        symbol: 'ETH',
        priceInr: 180000.0,
        timestamp: evaluatedAt,
      ));
      harness.addStopLossOrder(_order(
        id: 'sl_eth',
        tradeId: 'buy_eth',
        symbol: 'ETH',
        triggerPriceInr: 190000.0,
        quantity: 1.0,
      ));
      harness.addStopLossOrder(_order(
        id: 'sl_btc',
        tradeId: 'buy_btc',
        triggerPriceInr: 5100000.0,
      ));

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteStopLossSuccess>());
      final success = result as ExecuteStopLossSuccess;
      expect(success.executedSellCount, 2);
      expect(
        success.executedSells.map((sell) => sell.stopLossOrderId),
        ['sl_btc', 'sl_eth'],
      );
      expect(harness.transactionRepository.commitAttempts, 2);
      expect(harness.transactionRepository.trades.map((trade) => trade.id),
          ['trade_btc', 'trade_eth']);
    });

    test('ExecuteSell failure returns typed stop-loss failure and preserves it',
        () async {
      final harness = _Harness(evaluatedAt);
      harness.sellHoldingRepository.holdings.clear();
      harness.sellHoldingRepository.put(_holding(quantity: 0.1));
      harness.addStopLossOrder(
        _order(triggerPriceInr: 5100000.0, quantity: 0.5),
      );

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(_applicationCode(result),
          ExecuteStopLossFailureCode.executeSellFailure);
      final failure = result as ExecuteStopLossApplicationFailed;
      expect(failure.failedSellRequest!.orderId, 'sl_1');
      expect(failure.failedSellResult, isA<ExecuteSellDomainRejected>());
      expect(
        (failure.failedSellResult as ExecuteSellDomainRejected).failure.code,
        TradingFailureCode.insufficientHoldings,
      );
      expect(failure.executedSellsBeforeFailure, isEmpty);
    });

    test('wallet missing returns typed failure and short-circuits', () async {
      final harness = _Harness(evaluatedAt, addWallet: false);
      harness.addStopLossOrder(_order(triggerPriceInr: 5100000.0));

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(
        _applicationCode(result),
        ExecuteStopLossFailureCode.walletNotFound,
      );
      expect(harness.stopLossHoldingRepository.lookupCount, 0);
      expect(harness.stopLossOrderRepository.lookupCount, 0);
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('wallet repository failure returns typed application failure',
        () async {
      final harness = _Harness(evaluatedAt);
      harness.walletRepository.failLookup = true;

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(
        _applicationCode(result),
        ExecuteStopLossFailureCode.walletRepositoryFailure,
      );
    });

    test('stop-loss repository failure returns typed application failure',
        () async {
      final harness = _Harness(evaluatedAt);
      harness.stopLossOrderRepository.failLookup = true;

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(
        _applicationCode(result),
        ExecuteStopLossFailureCode.stopLossOrderRepositoryFailure,
      );
    });

    test('market provider failure returns typed application failure', () async {
      final harness = _Harness(evaluatedAt);
      harness.addStopLossOrder(_order(triggerPriceInr: 5100000.0));
      harness.marketProvider.failRepository = true;

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(
        _applicationCode(result),
        ExecuteStopLossFailureCode.marketRepositoryFailure,
      );
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('malformed active-order repository data is rejected before evaluation',
        () async {
      final harness = _Harness(evaluatedAt);
      harness.addStopLossOrder(_order(status: StopLossStatus.cancelled));

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(
        _applicationCode(result),
        ExecuteStopLossFailureCode.malformedRepositoryData,
      );
      expect(harness.marketProvider.requestedSymbols, isEmpty);
    });

    test('ownership mismatch is rejected for holdings and stop-loss orders',
        () async {
      final holdingHarness = _Harness(evaluatedAt, addHolding: false);
      holdingHarness.addHolding(_holding(userId: 'other_user'));

      final holdingResult =
          await holdingHarness.execute(evaluatedAt: evaluatedAt);

      expect(
        _applicationCode(holdingResult),
        ExecuteStopLossFailureCode.holdingOwnershipMismatch,
      );

      final orderHarness = _Harness(evaluatedAt);
      orderHarness.addStopLossOrder(_order(userId: 'other_user'));

      final orderResult = await orderHarness.execute(evaluatedAt: evaluatedAt);

      expect(
        _applicationCode(orderResult),
        ExecuteStopLossFailureCode.stopLossOrderOwnershipMismatch,
      );
    });

    test('TradingFailure from StopLossEngine is preserved in skipped details',
        () async {
      final harness = _Harness(evaluatedAt);
      harness.addStopLossOrder(
        _order(triggerPriceInr: 5100000.0, quantity: double.nan),
      );

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteStopLossSuccess>());
      final success = result as ExecuteStopLossSuccess;
      expect(success.rejectedOrderCount, 1);
      expect(
        success.evaluation.rejectedOrders.single.failure.code,
        TradingFailureCode.invalidSellQuantity,
      );
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('execution is deterministic for identical data and timestamp',
        () async {
      final first = _Harness(evaluatedAt);
      final second = _Harness(evaluatedAt);
      for (final harness in [first, second]) {
        harness.addStopLossOrder(_order(
          id: 'sl_eth',
          tradeId: 'buy_eth',
          symbol: 'ETH',
          triggerPriceInr: 190000.0,
          quantity: 1.0,
        ));
        harness.addStopLossOrder(_order(
          id: 'sl_btc',
          tradeId: 'buy_btc',
          triggerPriceInr: 5100000.0,
        ));
        harness.addHolding(_holding(
          id: 'holding_eth',
          symbol: 'ETH',
          quantity: 3.0,
          averageEntryPriceInr: 200000.0,
          currentPriceInr: 200000.0,
        ));
        harness.addTicker(_ticker(
          symbol: 'ETH',
          priceInr: 180000.0,
          timestamp: evaluatedAt,
        ));
      }

      final firstResult = await first.execute(evaluatedAt: evaluatedAt);
      final secondResult = await second.execute(evaluatedAt: evaluatedAt);

      expect(firstResult, isA<ExecuteStopLossSuccess>());
      expect(secondResult, isA<ExecuteStopLossSuccess>());
      final firstSuccess = firstResult as ExecuteStopLossSuccess;
      final secondSuccess = secondResult as ExecuteStopLossSuccess;
      expect(
        secondSuccess.executedSells.map((sell) => sell.stopLossOrderId),
        firstSuccess.executedSells.map((sell) => sell.stopLossOrderId),
      );
      expect(
        second.transactionRepository.trades.map((trade) => trade.toJson()),
        first.transactionRepository.trades.map((trade) => trade.toJson()),
      );
    });

    test(
        'result collections are immutable and repository lists are not mutated',
        () async {
      final harness = _Harness(evaluatedAt);
      final order = _order(triggerPriceInr: 5100000.0);
      harness.addStopLossOrder(order);
      final originalOrders = List<StopLossOrder>.of(
        harness.stopLossOrderRepository.orders,
      );

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteStopLossSuccess>());
      final success = result as ExecuteStopLossSuccess;
      expect(
        () => success.executedSells.add(success.executedSells.single),
        throwsUnsupportedError,
      );
      expect(
        () => success.evaluation.triggeredOrders.add(order),
        throwsUnsupportedError,
      );
      expect(harness.stopLossOrderRepository.orders, originalOrders);
      expect(harness.stopLossOrderRepository.persistenceCount, 0);
      expect(harness.stopLossHoldingRepository.persistenceCount, 0);
    });

    test('caller evaluatedAt is forwarded and clock fallback is deterministic',
        () async {
      final suppliedHarness = _Harness(evaluatedAt);
      suppliedHarness.addStopLossOrder(_order(triggerPriceInr: 5100000.0));

      final suppliedResult =
          await suppliedHarness.execute(evaluatedAt: evaluatedAt);

      expect(suppliedResult, isA<ExecuteStopLossSuccess>());
      expect(suppliedHarness.clock.callCount, 0);
      expect(
        (suppliedResult as ExecuteStopLossSuccess)
            .executedSells
            .single
            .sellRequest
            .evaluatedAt,
        evaluatedAt,
      );

      final clockHarness = _Harness(evaluatedAt);
      clockHarness.addStopLossOrder(_order(triggerPriceInr: 5100000.0));

      final clockResult = await clockHarness.execute();

      expect(clockResult, isA<ExecuteStopLossSuccess>());
      expect(clockHarness.clock.callCount, 1);
      expect(
        (clockResult as ExecuteStopLossSuccess)
            .executedSells
            .single
            .sellRequest
            .evaluatedAt,
        evaluatedAt,
      );
    });
  });
}

class _Harness {
  final List<String> callLog = [];
  late final FakeExecuteStopLossWalletRepository walletRepository;
  late final FakeExecuteStopLossHoldingRepository stopLossHoldingRepository;
  late final FakeExecuteBuyHoldingRepository sellHoldingRepository;
  late final FakeExecuteStopLossOrderRepository stopLossOrderRepository;
  late final FakeExecuteStopLossMarketProvider marketProvider;
  late final FakeTradingTransactionRepository transactionRepository;
  late final FakeExecuteStopLossClock clock;
  late final FakeExecuteBuyIdGenerator idGenerator;
  late final ExecuteStopLossUseCase useCase;

  _Harness(
    DateTime evaluatedAt, {
    bool addWallet = true,
    bool addHolding = true,
    List<String> tradeIds = const ['trade_1', 'trade_2', 'trade_3'],
  }) {
    walletRepository = FakeExecuteStopLossWalletRepository(callLog: callLog);
    stopLossHoldingRepository =
        FakeExecuteStopLossHoldingRepository(callLog: callLog);
    sellHoldingRepository = FakeExecuteBuyHoldingRepository();
    stopLossOrderRepository =
        FakeExecuteStopLossOrderRepository(callLog: callLog);
    marketProvider = FakeExecuteStopLossMarketProvider(callLog: callLog);
    clock = FakeExecuteStopLossClock(evaluatedAt);
    idGenerator = FakeExecuteBuyIdGenerator(tradeIds: tradeIds);

    if (addWallet) {
      walletRepository.put(
        userId: 'user_1',
        wallet: const VirtualWallet(balanceInr: 1000000.0, lockedInr: 0.0),
      );
    }
    if (addHolding) addHoldingModel(_holding());
    addTicker(_ticker(timestamp: evaluatedAt));

    transactionRepository = FakeTradingTransactionRepository(
      walletRepository: walletRepository,
      holdingRepository: sellHoldingRepository,
    );
    final executeSellUseCase = ExecuteSellUseCase(
      walletRepository: walletRepository,
      holdingRepository: sellHoldingRepository,
      marketProvider: marketProvider,
      transactionRepository: transactionRepository,
      tradingDomainService: const TradingDomainService(),
      clock: clock,
      idGenerator: idGenerator,
    );
    useCase = ExecuteStopLossUseCase(
      walletRepository: walletRepository,
      holdingRepository: stopLossHoldingRepository,
      stopLossOrderRepository: stopLossOrderRepository,
      marketProvider: marketProvider,
      stopLossEngine: const StopLossEngine(),
      executeSellUseCase: executeSellUseCase,
      clock: clock,
    );
  }

  void addHolding(Holding holding) => addHoldingModel(holding);

  void addHoldingModel(Holding holding) {
    stopLossHoldingRepository.put(holding);
    sellHoldingRepository.put(holding);
  }

  void addStopLossOrder(StopLossOrder order) {
    stopLossOrderRepository.put(order);
  }

  void addTicker(MarketTicker ticker) {
    marketProvider.putTicker(ticker);
  }

  Future<ExecuteStopLossResult> execute({DateTime? evaluatedAt}) {
    return useCase.execute(
      ExecuteStopLossRequest(
        userId: 'user_1',
        disciplineScoreAtTrade: 80,
        riskScoreAtTrade: 25,
        evaluatedAt: evaluatedAt,
      ),
    );
  }
}

ExecuteStopLossFailureCode _applicationCode(ExecuteStopLossResult result) {
  expect(result, isA<ExecuteStopLossApplicationFailed>());
  return (result as ExecuteStopLossApplicationFailed).failure.code;
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

StopLossOrder _order({
  String id = 'sl_1',
  String tradeId = 'buy_1',
  String userId = 'user_1',
  String symbol = 'BTC',
  double triggerPriceInr = 5100000.0,
  double quantity = 0.5,
  StopLossStatus status = StopLossStatus.active,
}) {
  return StopLossOrder(
    id: id,
    tradeId: tradeId,
    userId: userId,
    symbol: symbol,
    triggerPriceInr: triggerPriceInr,
    quantity: quantity,
    status: status,
    createdAt: DateTime.utc(2026, 7, 30, 9),
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
