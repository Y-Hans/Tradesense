import 'package:cryptoedu/features/trading/application/execute_buy_contracts.dart';
import 'package:cryptoedu/features/trading/application/execute_buy_result.dart';
import 'package:cryptoedu/features/trading/application/execute_buy_use_case.dart';
import 'package:cryptoedu/features/trading/domain/trading_domain_service.dart';
import 'package:cryptoedu/features/trading/domain/trading_failure.dart';
import 'package:cryptoedu/shared/models/crypto_asset.dart';
import 'package:cryptoedu/shared/models/holding.dart';
import 'package:cryptoedu/shared/models/market_ticker.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/execute_buy_fakes.dart';

void main() {
  group('ExecuteBuyUseCase', () {
    final evaluatedAt = DateTime.utc(2026, 7, 29, 10);

    test('successful first BUY loads dynamic state and commits atomically',
        () async {
      final harness = _Harness(evaluatedAt);

      final result = await harness.execute();

      expect(result, isA<ExecuteBuySuccess>());
      final success = result as ExecuteBuySuccess;
      expect(harness.walletRepository.lookupCount, 1);
      expect(harness.holdingRepository.lookupCount, 1);
      expect(harness.marketProvider.tickerLookupCount, 1);
      expect(harness.transactionRepository.commitAttempts, 1);
      expect(harness.transactionRepository.successfulCommits, 1);
      expect(success.domainDetails.amountSpentInr, 100000.0);
      expect(success.domainDetails.purchasedQuantity,
          closeTo(0.02, 0.000000000000000001));
      expect(success.updatedWallet.balanceInr, 9900000.0);
      expect(success.updatedHolding.id, 'holding_1');
      expect(success.updatedHolding.userId, 'user_1');
      expect(success.updatedHolding.symbol, 'BTC');
      expect(success.trade.id, 'trade_1');
      expect(success.trade.userId, 'user_1');
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
      expect(harness.transactionRepository.trades.single.toJson(),
          success.trade.toJson());
    });

    test('successful repeated BUY delegates weighted average calculation',
        () async {
      final harness = _Harness(
        evaluatedAt,
        wallet: const VirtualWallet(
          balanceInr: 1000.0,
          lockedInr: 0.0,
          initialBalanceInr: 1000.0,
        ),
        tickerPriceInr: 150.0,
      );
      harness.holdingRepository.put(
        const Holding(
          id: 'holding_existing',
          userId: 'user_1',
          symbol: 'BTC',
          quantity: 1.0,
          averageEntryPriceInr: 100.0,
          currentPriceInr: 100.0,
        ),
      );

      final result = await harness.execute(buyAmountInr: 300.0);

      expect(result, isA<ExecuteBuySuccess>());
      final success = result as ExecuteBuySuccess;
      expect(success.domainDetails.previousHoldingQuantity, 1.0);
      expect(success.domainDetails.newHoldingQuantity, 3.0);
      expect(success.domainDetails.previousCostBasisInr, 100.0);
      expect(success.domainDetails.newCostBasisInr, 400.0);
      expect(success.domainDetails.newAverageEntryPriceInr,
          closeTo(133.333333333333333, 1e-12));
      expect(success.updatedHolding.id, 'holding_existing');
      expect(harness.idGenerator.holdingIdCount, 0);
      expect(harness.transactionRepository.commitAttempts, 1);
    });

    test('wallet not found returns typed failure and short-circuits', () async {
      final harness = _Harness(evaluatedAt, addWallet: false);

      final result = await harness.execute();

      expect(_applicationCode(result), ExecuteBuyFailureCode.walletNotFound);
      expect(harness.walletRepository.lookupCount, 1);
      expect(harness.holdingRepository.lookupCount, 0);
      expect(harness.marketProvider.tickerLookupCount, 0);
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('ticker unavailable returns typed failure without state changes',
        () async {
      final harness = _Harness(evaluatedAt);
      harness.marketProvider.failUnavailable = true;
      final walletBefore =
          harness.walletRepository.wallets['user_1']!.wallet.toJson();
      final holdingsBefore = Map<String, Holding>.from(
        harness.holdingRepository.holdings,
      );

      final result = await harness.execute();

      expect(
        _applicationCode(result),
        ExecuteBuyFailureCode.marketTickerUnavailable,
      );
      expect(harness.transactionRepository.commitAttempts, 0);
      expect(harness.walletRepository.wallets['user_1']!.wallet.toJson(),
          walletBefore);
      expect(harness.holdingRepository.holdings, holdingsBefore);
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

    test('insufficient funds preserves the typed domain failure', () async {
      final harness = _Harness(
        evaluatedAt,
        wallet: const VirtualWallet(
          balanceInr: 100.0,
          lockedInr: 0.0,
          initialBalanceInr: 100.0,
        ),
      );

      final result = await harness.execute(buyAmountInr: 101.0);

      expect(_domainCode(result), TradingFailureCode.insufficientFunds);
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('mismatched holding preserves the typed domain failure', () async {
      final harness = _Harness(evaluatedAt);
      harness.holdingRepository.forcedHolding = const Holding(
        id: 'holding_eth',
        userId: 'user_1',
        symbol: 'ETH',
        quantity: 1.0,
        averageEntryPriceInr: 100.0,
        currentPriceInr: 100.0,
      );

      final result = await harness.execute();

      expect(_domainCode(result), TradingFailureCode.mismatchedHolding);
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('holding lookup failure returns typed application failure', () async {
      final harness = _Harness(evaluatedAt);
      harness.holdingRepository.failLookup = true;

      final result = await harness.execute();

      expect(
        _applicationCode(result),
        ExecuteBuyFailureCode.holdingRepositoryFailure,
      );
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('persistence failure never reports success or mutates fake storage',
        () async {
      final harness = _Harness(evaluatedAt);
      harness.transactionRepository.mode = FakeCommitMode.persistenceFailure;
      final walletBefore =
          harness.walletRepository.wallets['user_1']!.wallet.toJson();
      final holdingsBefore = Map<String, Holding>.from(
        harness.holdingRepository.holdings,
      );

      final result = await harness.execute();

      expect(
        _applicationCode(result),
        ExecuteBuyFailureCode.transactionPersistenceFailure,
      );
      expect(harness.transactionRepository.commitAttempts, 1);
      expect(harness.transactionRepository.successfulCommits, 0);
      expect(harness.transactionRepository.trades, isEmpty);
      expect(harness.walletRepository.wallets['user_1']!.wallet.toJson(),
          walletBefore);
      expect(harness.holdingRepository.holdings, holdingsBefore);
    });

    test('concurrency conflict returns typed failure with no partial state',
        () async {
      final harness = _Harness(evaluatedAt);
      harness.transactionRepository.beforeValidation = () {
        harness.walletRepository.put(
          userId: 'user_1',
          wallet: VirtualWallet.initial().copyWith(balanceInr: 9000000.0),
          version: 'v2',
        );
      };

      final result = await harness.execute();

      expect(
          _applicationCode(result), ExecuteBuyFailureCode.concurrencyConflict);
      expect(harness.transactionRepository.commitAttempts, 1);
      expect(harness.transactionRepository.successfulCommits, 0);
      expect(harness.transactionRepository.trades, isEmpty);
      expect(
        harness.walletRepository.wallets['user_1']!.wallet.balanceInr,
        9000000.0,
      );
      expect(harness.holdingRepository.holdings, isEmpty);
    });

    test('identical repositories, fake clock, and fake IDs are deterministic',
        () async {
      final firstHarness = _Harness(evaluatedAt);
      final secondHarness = _Harness(evaluatedAt);

      final first = await firstHarness.execute();
      final second = await secondHarness.execute();

      expect(first, isA<ExecuteBuySuccess>());
      expect(second, isA<ExecuteBuySuccess>());
      final firstSuccess = first as ExecuteBuySuccess;
      final secondSuccess = second as ExecuteBuySuccess;
      expect(secondSuccess.updatedWallet.toJson(),
          firstSuccess.updatedWallet.toJson());
      expect(secondSuccess.updatedHolding.toJson(),
          firstSuccess.updatedHolding.toJson());
      expect(secondSuccess.trade.toJson(), firstSuccess.trade.toJson());
      expect(secondSuccess.commitConfirmation.confirmationId,
          firstSuccess.commitConfirmation.confirmationId);
    });

    test('foreign wallet state cannot be used for a BUY', () async {
      final harness = _Harness(evaluatedAt);
      harness.walletRepository.forcedWallet = const PersistedVirtualWallet(
        userId: 'user_2',
        wallet: VirtualWallet(
          balanceInr: 10000000.0,
          lockedInr: 0.0,
        ),
        version: 'v1',
      );

      final result = await harness.execute();

      expect(
        _applicationCode(result),
        ExecuteBuyFailureCode.walletOwnershipMismatch,
      );
      expect(harness.transactionRepository.commitAttempts, 0);
    });

    test('foreign holding state cannot be used for a BUY', () async {
      final harness = _Harness(evaluatedAt);
      harness.holdingRepository.forcedHolding = const Holding(
        id: 'holding_foreign',
        userId: 'user_2',
        symbol: 'BTC',
        quantity: 1.0,
        averageEntryPriceInr: 100.0,
        currentPriceInr: 100.0,
      );

      final result = await harness.execute();

      expect(
        _applicationCode(result),
        ExecuteBuyFailureCode.holdingOwnershipMismatch,
      );
      expect(harness.transactionRepository.commitAttempts, 0);
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
  late final ExecuteBuyUseCase useCase;

  _Harness(
    DateTime evaluatedAt, {
    VirtualWallet wallet = const VirtualWallet(
      balanceInr: 10000000.0,
      lockedInr: 0.0,
    ),
    double tickerPriceInr = 5000000.0,
    bool addWallet = true,
  })  : walletRepository = FakeExecuteBuyWalletRepository(),
        holdingRepository = FakeExecuteBuyHoldingRepository(),
        marketProvider = FakeMarketProvider(),
        clock = FakeExecuteBuyClock(evaluatedAt),
        idGenerator = FakeExecuteBuyIdGenerator() {
    if (addWallet) {
      walletRepository.put(userId: 'user_1', wallet: wallet);
    }
    marketProvider.putTicker(
      _ticker(priceInr: tickerPriceInr, timestamp: evaluatedAt),
    );
    transactionRepository = FakeTradingTransactionRepository(
      walletRepository: walletRepository,
      holdingRepository: holdingRepository,
    );
    useCase = ExecuteBuyUseCase(
      walletRepository: walletRepository,
      holdingRepository: holdingRepository,
      marketProvider: marketProvider,
      transactionRepository: transactionRepository,
      tradingDomainService: const TradingDomainService(),
      clock: clock,
      idGenerator: idGenerator,
    );
  }

  Future<ExecuteBuyResult> execute({
    double buyAmountInr = 100000.0,
    CryptoAsset? asset,
  }) {
    return useCase.execute(
      ExecuteBuyRequest(
        userId: 'user_1',
        asset: asset ?? _asset(),
        buyAmountInr: buyAmountInr,
        disciplineScoreAtTrade: 80,
        riskScoreAtTrade: 25,
      ),
    );
  }
}

ExecuteBuyFailureCode _applicationCode(ExecuteBuyResult result) {
  expect(result, isA<ExecuteBuyApplicationFailed>());
  return (result as ExecuteBuyApplicationFailed).failure.code;
}

TradingFailureCode _domainCode(ExecuteBuyResult result) {
  expect(result, isA<ExecuteBuyDomainRejected>());
  return (result as ExecuteBuyDomainRejected).failure.code;
}

CryptoAsset _asset({
  String symbol = 'BTC',
  String name = 'Bitcoin',
  double currentPriceInr = 5000000.0,
}) {
  return CryptoAsset(
    symbol: symbol,
    name: name,
    iconUrl: 'assets/icons/btc.png',
    currentPriceInr: currentPriceInr,
    change24hPercent: 1.0,
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
