import 'package:cryptoedu/features/portfolio/application/execute_portfolio_result.dart';
import 'package:cryptoedu/features/portfolio/application/execute_portfolio_use_case.dart';
import 'package:cryptoedu/features/portfolio/domain/portfolio_engine.dart';
import 'package:cryptoedu/features/portfolio/domain/portfolio_engine_result.dart';
import 'package:cryptoedu/features/trading/application/execute_buy_contracts.dart';
import 'package:cryptoedu/features/trading/application/trading_event_publisher.dart';
import 'package:cryptoedu/features/trading/application/trading_events.dart';
import 'package:cryptoedu/features/trading/domain/trading_failure.dart';
import 'package:cryptoedu/shared/models/holding.dart';
import 'package:cryptoedu/shared/models/market_ticker.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/execute_portfolio_fakes.dart';

void main() {
  group('ExecutePortfolioUseCase', () {
    final evaluatedAt = DateTime.utc(2026, 7, 30, 10);

    test('successful portfolio calculation loads all read-side inputs',
        () async {
      final harness = _Harness(evaluatedAt);

      final result = await harness.execute();

      expect(result, isA<ExecutePortfolioSuccess>());
      final success = result as ExecutePortfolioSuccess;
      expect(harness.walletRepository.lookupCount, 1);
      expect(harness.holdingRepository.lookupCount, 1);
      expect(harness.tradeRepository.lookupCount, 1);
      expect(harness.marketProvider.tickerLookupCount, 2);
      expect(success.snapshot.totals.cashBalanceInr, 1000.0);
      expect(success.snapshot.totals.cryptoValueInr, 350.0);
      expect(success.snapshot.totals.portfolioValueInr, 1350.0);
      expect(success.snapshot.assetSummaries.map((asset) => asset.assetSymbol),
          ['BTC', 'ETH']);
      expect(harness.events, hasLength(1));
      expect(harness.events.single, isA<PortfolioViewed>());
      final event = harness.events.single as PortfolioViewed;
      expect(event.userId, 'user_1');
      expect(event.portfolioValueInr, 1350.0);
      expect(event.numberOfAssets, 2);
      expect(event.numberOfOpenHoldings, 2);
    });

    test('repository and provider calls happen in the expected order',
        () async {
      final harness = _Harness(evaluatedAt);

      await harness.execute();

      expect(harness.callLog, [
        'wallet:user_1',
        'holdings:user_1',
        'trades:user_1',
        'ticker:BTC',
        'ticker:ETH',
      ]);
    });

    test('only required unique held asset tickers are requested', () async {
      final harness = _Harness(evaluatedAt, addDefaultHoldings: false);
      harness.holdingRepository
        ..put(_holding(id: 'holding_eth', symbol: 'ETH'))
        ..put(_holding(id: 'holding_btc', symbol: 'BTC'));
      harness.marketProvider
        ..putTicker(_ticker(evaluatedAt, symbol: 'BTC', priceInr: 120.0))
        ..putTicker(_ticker(evaluatedAt, symbol: 'ETH', priceInr: 90.0))
        ..putTicker(_ticker(evaluatedAt, symbol: 'SOL', priceInr: 10.0));

      final result = await harness.execute();

      expect(result, isA<ExecutePortfolioSuccess>());
      expect(harness.marketProvider.requestedSymbols, ['BTC', 'ETH']);
    });

    test('duplicate holding symbols do not duplicate ticker requests',
        () async {
      final harness = _Harness(evaluatedAt, addDefaultHoldings: false);
      harness.holdingRepository
        ..put(_holding(id: 'holding_btc_1', symbol: 'BTC'))
        ..put(_holding(id: 'holding_btc_2', symbol: ' btc '));
      harness.marketProvider.putTicker(
        _ticker(evaluatedAt, symbol: 'BTC', priceInr: 120.0),
      );

      final result = await harness.execute();

      expect(_domainCode(result), TradingFailureCode.invalidExistingHolding);
      expect(harness.marketProvider.requestedSymbols, ['BTC']);
    });

    test('empty cash-only portfolio succeeds without ticker calls', () async {
      final harness = _Harness(evaluatedAt, addDefaultHoldings: false);

      final result = await harness.execute();

      expect(result, isA<ExecutePortfolioSuccess>());
      final success = result as ExecutePortfolioSuccess;
      expect(success.snapshot.totals.portfolioValueInr, 1000.0);
      expect(success.snapshot.totals.cashAllocationPercent, 100.0);
      expect(success.snapshot.assetSummaries, isEmpty);
      expect(harness.marketProvider.tickerLookupCount, 0);
      expect(harness.marketProvider.requestedSymbols, isEmpty);
    });

    test('wallet missing returns typed failure and short-circuits', () async {
      final harness = _Harness(evaluatedAt, addWallet: false);

      final result = await harness.execute();

      expect(
        _applicationCode(result),
        ExecutePortfolioFailureCode.walletNotFound,
      );
      expect(harness.holdingRepository.lookupCount, 0);
      expect(harness.tradeRepository.lookupCount, 0);
      expect(harness.marketProvider.tickerLookupCount, 0);
    });

    test('wallet repository failure returns typed failure', () async {
      final harness = _Harness(evaluatedAt);
      harness.walletRepository.failLookup = true;

      final result = await harness.execute();

      expect(
        _applicationCode(result),
        ExecutePortfolioFailureCode.walletRepositoryFailure,
      );
      expect(harness.holdingRepository.lookupCount, 0);
    });

    test('holdings repository failure returns typed failure', () async {
      final harness = _Harness(evaluatedAt);
      harness.holdingRepository.failLookup = true;

      final result = await harness.execute();

      expect(
        _applicationCode(result),
        ExecutePortfolioFailureCode.holdingsRepositoryFailure,
      );
      expect(harness.tradeRepository.lookupCount, 0);
      expect(harness.marketProvider.tickerLookupCount, 0);
    });

    test('trades repository failure returns typed failure', () async {
      final harness = _Harness(evaluatedAt);
      harness.tradeRepository.failLookup = true;

      final result = await harness.execute();

      expect(
        _applicationCode(result),
        ExecutePortfolioFailureCode.tradesRepositoryFailure,
      );
      expect(harness.marketProvider.tickerLookupCount, 0);
    });

    test('market provider failure returns typed failure', () async {
      final harness = _Harness(evaluatedAt);
      harness.marketProvider.failRepository = true;

      final result = await harness.execute();

      expect(
        _applicationCode(result),
        ExecutePortfolioFailureCode.marketRepositoryFailure,
      );
    });

    test('missing ticker for held asset returns typed failure', () async {
      final harness = _Harness(evaluatedAt);
      harness.marketProvider.tickers.remove('ETH');

      final result = await harness.execute();

      expect(
        _applicationCode(result),
        ExecutePortfolioFailureCode.marketTickerUnavailable,
      );
      expect(harness.marketProvider.requestedSymbols, ['BTC', 'ETH']);
    });

    test('foreign wallet and foreign collections are rejected', () async {
      final foreignWalletHarness = _Harness(evaluatedAt);
      foreignWalletHarness.walletRepository.forcedWallet =
          _persistedWallet(userId: 'user_2');

      final foreignWalletResult = await foreignWalletHarness.execute();

      expect(
        _applicationCode(foreignWalletResult),
        ExecutePortfolioFailureCode.walletOwnershipMismatch,
      );

      final foreignHoldingHarness = _Harness(evaluatedAt);
      foreignHoldingHarness.holdingRepository.put(
        _holding(id: 'foreign_holding', userId: 'user_2', symbol: 'SOL'),
      );

      final foreignHoldingResult = await foreignHoldingHarness.execute();

      expect(
        _applicationCode(foreignHoldingResult),
        ExecutePortfolioFailureCode.holdingOwnershipMismatch,
      );

      final foreignTradeHarness = _Harness(evaluatedAt);
      foreignTradeHarness.tradeRepository.put(
        _trade(id: 'foreign_trade', userId: 'user_2', symbol: 'SOL'),
      );

      final foreignTradeResult = await foreignTradeHarness.execute();

      expect(
        _applicationCode(foreignTradeResult),
        ExecutePortfolioFailureCode.tradeOwnershipMismatch,
      );
    });

    test('Portfolio Engine rejection is preserved', () async {
      final harness = _Harness(
        evaluatedAt,
        wallet: const VirtualWallet(
          balanceInr: -1.0,
          lockedInr: 0.0,
          initialBalanceInr: 1000.0,
        ),
      );

      final result = await harness.execute();

      expect(_domainCode(result), TradingFailureCode.invalidWallet);
    });

    test('result contains the exact snapshot returned by the domain flow',
        () async {
      final fixedSnapshot = _snapshot(evaluatedAt);
      final engine = _FakePortfolioEngine(
        PortfolioEngineSuccess(snapshot: fixedSnapshot),
      );
      final harness = _Harness(evaluatedAt, portfolioEngine: engine);

      final result = await harness.execute();

      expect(result, isA<ExecutePortfolioSuccess>());
      expect((result as ExecutePortfolioSuccess).snapshot, same(fixedSnapshot));
    });

    test('no persistence or commit-like method is called', () async {
      final harness = _Harness(evaluatedAt);

      await harness.execute();

      expect(harness.walletRepository.commitSnapshotCount, 0);
      expect(harness.holdingRepository.commitSnapshotCount, 0);
      expect(harness.tradeRepository.commitSnapshotCount, 0);
    });

    test('identical repository data and timestamp are deterministic', () async {
      final firstHarness = _Harness(evaluatedAt, reverseDefaultHoldings: true);
      final secondHarness = _Harness(evaluatedAt);

      final first = await firstHarness.execute();
      final second = await secondHarness.execute();

      expect(first, isA<ExecutePortfolioSuccess>());
      expect(second, isA<ExecutePortfolioSuccess>());
      final firstSnapshot = (first as ExecutePortfolioSuccess).snapshot;
      final secondSnapshot = (second as ExecutePortfolioSuccess).snapshot;
      expect(
        secondSnapshot.totals.portfolioValueInr,
        firstSnapshot.totals.portfolioValueInr,
      );
      expect(
        secondSnapshot.assetSummaries.map((asset) => asset.assetSymbol),
        firstSnapshot.assetSummaries.map((asset) => asset.assetSymbol),
      );
      expect(
        secondSnapshot.totals.totalRealizedProfitLossInr,
        firstSnapshot.totals.totalRealizedProfitLossInr,
      );
    });

    test('request remains immutable and evaluatedAt is forwarded correctly',
        () async {
      final engine = _FakePortfolioEngine(
        PortfolioEngineSuccess(snapshot: _snapshot(evaluatedAt)),
      );
      final harness = _Harness(evaluatedAt, portfolioEngine: engine);
      final request = ExecutePortfolioRequest(
        userId: ' user_1 ',
        evaluatedAt: evaluatedAt,
      );

      await harness.useCase.execute(request);

      expect(request.userId, ' user_1 ');
      expect(request.evaluatedAt, evaluatedAt);
      expect(engine.lastEvaluatedAt, evaluatedAt);
      expect(harness.clock.callCount, 0);
    });

    test('clock is isolated and used only when request omits evaluatedAt',
        () async {
      final clockAt = DateTime.utc(2026, 7, 30, 11);
      final harness = _Harness(clockAt);

      final result = await harness.useCase.execute(
        const ExecutePortfolioRequest(userId: 'user_1'),
      );

      expect(result, isA<ExecutePortfolioSuccess>());
      expect((result as ExecutePortfolioSuccess).snapshot.evaluatedAt, clockAt);
      expect(harness.clock.callCount, 1);
    });

    test('repository collections are not mutated', () async {
      final harness = _Harness(evaluatedAt, reverseDefaultHoldings: true);
      final holdingOrderBefore = harness.holdingRepository.holdings
          .map((holding) => holding.symbol)
          .toList(growable: false);
      final tradeOrderBefore = harness.tradeRepository.trades
          .map((trade) => trade.id)
          .toList(growable: false);

      await harness.execute();

      expect(
        harness.holdingRepository.holdings
            .map((holding) => holding.symbol)
            .toList(growable: false),
        holdingOrderBefore,
      );
      expect(
        harness.tradeRepository.trades
            .map((trade) => trade.id)
            .toList(growable: false),
        tradeOrderBefore,
      );
    });
  });
}

ExecutePortfolioFailureCode _applicationCode(ExecutePortfolioResult result) {
  expect(result, isA<ExecutePortfolioApplicationFailed>());
  return (result as ExecutePortfolioApplicationFailed).failure.code;
}

TradingFailureCode _domainCode(ExecutePortfolioResult result) {
  expect(result, isA<ExecutePortfolioDomainRejected>());
  return (result as ExecutePortfolioDomainRejected).failure.code;
}

class _Harness {
  final DateTime evaluatedAt;
  final List<String> callLog = [];
  late final FakeExecutePortfolioWalletRepository walletRepository;
  late final FakeExecutePortfolioHoldingRepository holdingRepository;
  late final FakeExecutePortfolioTradeRepository tradeRepository;
  late final FakeExecutePortfolioMarketProvider marketProvider;
  late final FakeExecutePortfolioClock clock;
  late final InMemoryTradingEventPublisher eventPublisher;
  final List<TradingEvent> events = [];
  late final ExecutePortfolioUseCase useCase;

  _Harness(
    this.evaluatedAt, {
    bool addWallet = true,
    bool addDefaultHoldings = true,
    bool reverseDefaultHoldings = false,
    VirtualWallet wallet = const VirtualWallet(
      balanceInr: 1000.0,
      lockedInr: 0.0,
      initialBalanceInr: 1000.0,
    ),
    PortfolioEngine? portfolioEngine,
  }) {
    walletRepository = FakeExecutePortfolioWalletRepository(callLog: callLog);
    holdingRepository = FakeExecutePortfolioHoldingRepository(callLog: callLog);
    tradeRepository = FakeExecutePortfolioTradeRepository(callLog: callLog);
    marketProvider = FakeExecutePortfolioMarketProvider(callLog: callLog);
    clock = FakeExecutePortfolioClock(evaluatedAt);
    eventPublisher = InMemoryTradingEventPublisher();
    eventPublisher.subscribe(events.add);
    useCase = ExecutePortfolioUseCase(
      walletRepository: walletRepository,
      holdingRepository: holdingRepository,
      tradeRepository: tradeRepository,
      marketProvider: marketProvider,
      portfolioEngine: portfolioEngine ?? const PortfolioEngine(),
      clock: clock,
      eventPublisher: eventPublisher,
    );

    if (addWallet) {
      walletRepository.wallets['user_1'] = _persistedWallet(wallet: wallet);
    }
    if (addDefaultHoldings) {
      final holdings = [
        _holding(id: 'holding_btc', symbol: 'BTC'),
        _holding(id: 'holding_eth', symbol: 'ETH', quantity: 2.0),
      ];
      for (final holding
          in reverseDefaultHoldings ? holdings.reversed : holdings) {
        holdingRepository.put(holding);
      }
    }
    tradeRepository
      ..put(
        _trade(
          id: 'trade_buy_btc',
          symbol: 'BTC',
          side: TradeSide.buy,
          quantity: 1.0,
          executionPriceInr: 100.0,
          totalAmountInr: 100.0,
          timestamp: DateTime.utc(2026, 7, 30, 8),
        ),
      )
      ..put(
        _trade(
          id: 'trade_buy_eth',
          symbol: 'ETH',
          side: TradeSide.buy,
          quantity: 2.0,
          executionPriceInr: 100.0,
          totalAmountInr: 200.0,
          timestamp: DateTime.utc(2026, 7, 30, 9),
        ),
      );
    marketProvider
      ..putTicker(_ticker(evaluatedAt, symbol: 'BTC', priceInr: 150.0))
      ..putTicker(_ticker(evaluatedAt, symbol: 'ETH', priceInr: 100.0));
  }

  Future<ExecutePortfolioResult> execute({
    DateTime? evaluatedAt,
  }) {
    return useCase.execute(
      ExecutePortfolioRequest(
        userId: 'user_1',
        evaluatedAt: evaluatedAt ?? this.evaluatedAt,
      ),
    );
  }
}

class _FakePortfolioEngine extends PortfolioEngine {
  final PortfolioEngineResult result;
  DateTime? lastEvaluatedAt;

  _FakePortfolioEngine(this.result);

  @override
  PortfolioEngineResult calculate({
    required VirtualWallet wallet,
    required List<Holding> holdings,
    required List<MarketTicker> tickers,
    List<Trade> trades = const [],
    required DateTime evaluatedAt,
  }) {
    lastEvaluatedAt = evaluatedAt;
    return result;
  }
}

PersistedVirtualWallet _persistedWallet({
  String userId = 'user_1',
  VirtualWallet wallet = const VirtualWallet(
    balanceInr: 1000.0,
    lockedInr: 0.0,
    initialBalanceInr: 1000.0,
  ),
}) {
  return PersistedVirtualWallet(
    userId: userId,
    wallet: wallet,
    version: 'v1',
    updatedAt: DateTime.utc(2026, 7, 30, 9),
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

MarketTicker _ticker(
  DateTime evaluatedAt, {
  String symbol = 'BTC',
  double priceInr = 100.0,
}) {
  return MarketTicker(
    symbol: symbol,
    priceInr: priceInr,
    high24h: priceInr * 1.1,
    low24h: priceInr * 0.9,
    volume24h: 1000000.0,
    timestamp: evaluatedAt,
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
    timestamp: timestamp ?? DateTime.utc(2026, 7, 30, 9),
    disciplineScoreAtTrade: 80,
    riskScoreAtTrade: 25,
  );
}

PortfolioSnapshot _snapshot(DateTime evaluatedAt) {
  return PortfolioSnapshot(
    wallet: const WalletSummary(
      cashBalanceInr: 1000.0,
      lockedBalanceInr: 0.0,
      availableBalanceInr: 1000.0,
      initialBalanceInr: 1000.0,
    ),
    totals: PortfolioTotals(
      cashBalanceInr: 1000.0,
      cryptoValueInr: 0.0,
      portfolioValueInr: 1000.0,
      investedAmountInr: 0.0,
      totalCostBasisInr: 0.0,
      totalUnrealizedProfitLossInr: 0.0,
      totalRealizedProfitLossInr: 0.0,
      overallProfitLossInr: 0.0,
      overallReturnPercent: 0.0,
      cashAllocationPercent: 100.0,
      cryptoAllocationPercent: 0.0,
      numberOfAssets: 0,
      numberOfOpenHoldings: 0,
      evaluatedAt: evaluatedAt,
    ),
    assetSummaries: const [],
    allocation: const AllocationSummary(
      cashPercent: 100.0,
      cryptoPercent: 0.0,
      assets: [],
    ),
    performance: const PortfolioPerformance(
      bestPerformingAsset: null,
      worstPerformingAsset: null,
      largestPosition: null,
      smallestPosition: null,
      highestAllocation: null,
      lowestAllocation: null,
    ),
    evaluatedAt: evaluatedAt,
  );
}
