import 'package:cryptoedu/features/trading/application/execute_trade_history_result.dart';
import 'package:cryptoedu/features/trading/application/execute_trade_history_use_case.dart';
import 'package:cryptoedu/features/trading/application/execute_buy_contracts.dart';
import 'package:cryptoedu/features/trading/application/trading_event_publisher.dart';
import 'package:cryptoedu/features/trading/application/trading_events.dart';
import 'package:cryptoedu/features/trading/domain/trade_history_engine.dart';
import 'package:cryptoedu/features/trading/domain/trade_history_result.dart';
import 'package:cryptoedu/features/trading/domain/trading_failure.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/execute_trade_history_fakes.dart';

void main() {
  group('ExecuteTradeHistoryUseCase', () {
    final evaluatedAt = DateTime.utc(2026, 7, 30, 12);

    test('successful history retrieval delegates to TradeHistoryEngine',
        () async {
      final harness = _Harness(evaluatedAt, addDefaultTrades: false);
      harness.addTrade(_buy(id: 'buy_2', timestamp: DateTime.utc(2026, 7, 30)));
      harness.addTrade(_buy(id: 'buy_1', timestamp: DateTime.utc(2026, 7, 29)));

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteTradeHistorySuccess>());
      final success = result as ExecuteTradeHistorySuccess;
      expect(success.snapshot.summary.totalTrades, 2);
      expect(success.snapshot.replay.orderedTrades.map((trade) => trade.id), [
        'buy_1',
        'buy_2',
      ]);
      expect(success.evaluatedAt, evaluatedAt);
      expect(harness.callLog, ['wallet:user_1', 'trades:user_1']);
      expect(harness.events, hasLength(1));
      expect(harness.events.single, isA<TradeHistoryViewed>());
      final event = harness.events.single as TradeHistoryViewed;
      expect(event.userId, 'user_1');
      expect(event.totalTrades, 2);
      expect(event.profitableTrades, 0);
      expect(event.losingTrades, 0);
    });

    test('empty history returns a successful empty engine snapshot', () async {
      final harness = _Harness(evaluatedAt, addDefaultTrades: false);

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteTradeHistorySuccess>());
      final success = result as ExecuteTradeHistorySuccess;
      expect(success.snapshot.timeline, isEmpty);
      expect(success.snapshot.assetAnalytics, isEmpty);
      expect(success.snapshot.replay.orderedTrades, isEmpty);
      expect(success.snapshot.summary.totalTrades, 0);
      expect(success.snapshot.evaluatedAt, evaluatedAt);
    });

    test('wallet missing returns typed application failure', () async {
      final harness = _Harness(evaluatedAt, addWallet: false);

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(
        _applicationCode(result),
        ExecuteTradeHistoryFailureCode.walletNotFound,
      );
      expect(harness.tradeRepository.lookupCount, 0);
    });

    test('invalid user returns typed application failure without lookups',
        () async {
      final harness = _Harness(evaluatedAt);

      final result = await harness.execute(userId: '   ');

      expect(
        _applicationCode(result),
        ExecuteTradeHistoryFailureCode.invalidUserContext,
      );
      expect(harness.walletRepository.lookupCount, 0);
      expect(harness.tradeRepository.lookupCount, 0);
      expect(harness.callLog, isEmpty);
    });

    test('repository failures are mapped to typed application failures',
        () async {
      final walletHarness = _Harness(evaluatedAt);
      walletHarness.walletRepository.failLookup = true;

      final walletResult =
          await walletHarness.execute(evaluatedAt: evaluatedAt);

      expect(
        _applicationCode(walletResult),
        ExecuteTradeHistoryFailureCode.walletRepositoryFailure,
      );
      expect(walletHarness.tradeRepository.lookupCount, 0);

      final tradeHarness = _Harness(evaluatedAt);
      tradeHarness.tradeRepository.failLookup = true;

      final tradeResult = await tradeHarness.execute(evaluatedAt: evaluatedAt);

      expect(
        _applicationCode(tradeResult),
        ExecuteTradeHistoryFailureCode.tradesRepositoryFailure,
      );
    });

    test('malformed repository trade data is rejected before delegation',
        () async {
      final engine = _FakeTradeHistoryEngine(
        TradeHistorySuccess(snapshot: _emptySnapshot(evaluatedAt)),
      );
      final harness = _Harness(
        evaluatedAt,
        tradeHistoryEngine: engine,
        addDefaultTrades: false,
      );
      harness.addTrade(_buy(userId: ' '));

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(
        _applicationCode(result),
        ExecuteTradeHistoryFailureCode.malformedRepositoryData,
      );
      expect(engine.callCount, 0);
    });

    test('ownership mismatch is rejected for wallets and trades', () async {
      final walletHarness = _Harness(evaluatedAt);
      walletHarness.walletRepository.forcedWallet =
          const PersistedVirtualWallet(
        userId: 'user_2',
        wallet: VirtualWallet(balanceInr: 1000.0, lockedInr: 0.0),
      );

      final walletResult =
          await walletHarness.execute(evaluatedAt: evaluatedAt);

      expect(
        _applicationCode(walletResult),
        ExecuteTradeHistoryFailureCode.walletOwnershipMismatch,
      );

      final tradeHarness = _Harness(evaluatedAt, addDefaultTrades: false);
      tradeHarness.addTrade(_buy(userId: 'user_2'));

      final tradeResult = await tradeHarness.execute(evaluatedAt: evaluatedAt);

      expect(
        _applicationCode(tradeResult),
        ExecuteTradeHistoryFailureCode.tradeOwnershipMismatch,
      );
    });

    test('result contains the exact snapshot returned by the domain flow',
        () async {
      final fixedSnapshot = _emptySnapshot(evaluatedAt);
      final engine = _FakeTradeHistoryEngine(
        TradeHistorySuccess(snapshot: fixedSnapshot),
      );
      final harness = _Harness(evaluatedAt, tradeHistoryEngine: engine);

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteTradeHistorySuccess>());
      expect(
          (result as ExecuteTradeHistorySuccess).snapshot, same(fixedSnapshot));
    });

    test('identical repository data and timestamp are deterministic', () async {
      final firstHarness = _Harness(evaluatedAt, reverseDefaultTrades: true);
      final secondHarness = _Harness(evaluatedAt);

      final first = await firstHarness.execute(evaluatedAt: evaluatedAt);
      final second = await secondHarness.execute(evaluatedAt: evaluatedAt);

      expect(first, isA<ExecuteTradeHistorySuccess>());
      expect(second, isA<ExecuteTradeHistorySuccess>());
      final firstSnapshot = (first as ExecuteTradeHistorySuccess).snapshot;
      final secondSnapshot = (second as ExecuteTradeHistorySuccess).snapshot;
      expect(firstSnapshot.timeline.map((entry) => entry.trade.id), [
        'buy_1',
        'sell_1',
      ]);
      expect(
        secondSnapshot.timeline.map((entry) => entry.trade.id),
        firstSnapshot.timeline.map((entry) => entry.trade.id),
      );
      expect(secondSnapshot.summary.totalTrades,
          firstSnapshot.summary.totalTrades);
      expect(secondSnapshot.summary.netRealizedProfitLossInr,
          firstSnapshot.summary.netRealizedProfitLossInr);
    });

    test('snapshot collections are immutable', () async {
      final harness = _Harness(evaluatedAt);

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteTradeHistorySuccess>());
      final snapshot = (result as ExecuteTradeHistorySuccess).snapshot;
      expect(() => snapshot.timeline.clear(), throwsUnsupportedError);
      expect(() => snapshot.assetAnalytics.clear(), throwsUnsupportedError);
      expect(
          () => snapshot.replay.orderedTrades.clear(), throwsUnsupportedError);
      expect(() => snapshot.replay.steps.clear(), throwsUnsupportedError);
    });

    test('repository trade list is copied and sorted before delegation',
        () async {
      final engine = _FakeTradeHistoryEngine(
        TradeHistorySuccess(snapshot: _emptySnapshot(evaluatedAt)),
      );
      final harness = _Harness(
        evaluatedAt,
        tradeHistoryEngine: engine,
        addDefaultTrades: false,
      );
      final later = _buy(id: 'buy_later', timestamp: DateTime.utc(2026, 7, 30));
      final earlier =
          _buy(id: 'buy_earlier', timestamp: DateTime.utc(2026, 7, 29));
      harness.addTrade(later);
      harness.addTrade(earlier);

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteTradeHistorySuccess>());
      expect(engine.lastTrades, isNot(same(harness.tradeRepository.trades)));
      expect(engine.lastTrades!.map((trade) => trade.id), [
        'buy_earlier',
        'buy_later',
      ]);
      expect(harness.tradeRepository.trades, [later, earlier]);
    });

    test('evaluatedAt is forwarded and clock fallback is deterministic',
        () async {
      final suppliedEngine = _FakeTradeHistoryEngine(
        TradeHistorySuccess(snapshot: _emptySnapshot(evaluatedAt)),
      );
      final suppliedHarness = _Harness(
        evaluatedAt,
        tradeHistoryEngine: suppliedEngine,
      );

      final suppliedResult =
          await suppliedHarness.execute(evaluatedAt: evaluatedAt);

      expect(suppliedResult, isA<ExecuteTradeHistorySuccess>());
      expect(suppliedEngine.lastEvaluatedAt, evaluatedAt);
      expect(suppliedHarness.clock.callCount, 0);

      final fallbackEngine = _FakeTradeHistoryEngine(
        TradeHistorySuccess(snapshot: _emptySnapshot(evaluatedAt)),
      );
      final fallbackHarness = _Harness(
        evaluatedAt,
        tradeHistoryEngine: fallbackEngine,
      );

      final fallbackResult = await fallbackHarness.execute();

      expect(fallbackResult, isA<ExecuteTradeHistorySuccess>());
      expect(fallbackEngine.lastEvaluatedAt, evaluatedAt);
      expect(fallbackHarness.clock.callCount, 1);
    });

    test('no persistence occurs during history retrieval', () async {
      final harness = _Harness(evaluatedAt);

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteTradeHistorySuccess>());
      expect(harness.walletRepository.commitSnapshotCount, 0);
      expect(harness.tradeRepository.commitSnapshotCount, 0);
    });

    test('repository interactions happen in wallet then trades order',
        () async {
      final harness = _Harness(evaluatedAt);

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(result, isA<ExecuteTradeHistorySuccess>());
      expect(harness.callLog, ['wallet:user_1', 'trades:user_1']);
    });

    test('TradingFailure from TradeHistoryEngine is preserved', () async {
      final harness = _Harness(evaluatedAt, addDefaultTrades: false);
      harness.addTrade(_sell(id: 'sell_without_buy'));

      final result = await harness.execute(evaluatedAt: evaluatedAt);

      expect(_domainCode(result), TradingFailureCode.insufficientHoldings);
    });
  });
}

class _Harness {
  static const userId = 'user_1';

  final List<String> callLog = [];
  late final FakeExecuteTradeHistoryWalletRepository walletRepository;
  late final FakeExecuteTradeHistoryTradeRepository tradeRepository;
  late final FakeExecuteTradeHistoryClock clock;
  late final InMemoryTradingEventPublisher eventPublisher;
  final List<TradingEvent> events = [];
  late final ExecuteTradeHistoryUseCase useCase;

  _Harness(
    DateTime evaluatedAt, {
    TradeHistoryEngine? tradeHistoryEngine,
    bool addWallet = true,
    bool addDefaultTrades = true,
    bool reverseDefaultTrades = false,
  }) {
    walletRepository = FakeExecuteTradeHistoryWalletRepository(
      callLog: callLog,
    );
    tradeRepository = FakeExecuteTradeHistoryTradeRepository(
      callLog: callLog,
    );
    clock = FakeExecuteTradeHistoryClock(evaluatedAt);
    eventPublisher = InMemoryTradingEventPublisher();
    eventPublisher.subscribe(events.add);
    useCase = ExecuteTradeHistoryUseCase(
      walletRepository: walletRepository,
      tradeRepository: tradeRepository,
      tradeHistoryEngine: tradeHistoryEngine ?? const TradeHistoryEngine(),
      clock: clock,
      eventPublisher: eventPublisher,
    );

    if (addWallet) {
      walletRepository.put(
        userId: userId,
        wallet: const VirtualWallet(balanceInr: 9990000.0, lockedInr: 0.0),
      );
    }

    if (addDefaultTrades) {
      final trades = [
        _buy(
          id: 'buy_1',
          quantity: 2.0,
          executionPriceInr: 100.0,
          timestamp: DateTime.utc(2026, 7, 29, 9),
        ),
        _sell(
          id: 'sell_1',
          quantity: 1.0,
          executionPriceInr: 150.0,
          timestamp: DateTime.utc(2026, 7, 30, 9),
        ),
      ];
      for (final trade in reverseDefaultTrades ? trades.reversed : trades) {
        tradeRepository.put(trade);
      }
    }
  }

  void addTrade(Trade trade) {
    tradeRepository.put(trade);
  }

  Future<ExecuteTradeHistoryResult> execute({
    String userId = _Harness.userId,
    DateTime? evaluatedAt,
  }) {
    return useCase.execute(
      ExecuteTradeHistoryRequest(
        userId: userId,
        evaluatedAt: evaluatedAt,
      ),
    );
  }
}

class _FakeTradeHistoryEngine extends TradeHistoryEngine {
  final TradeHistoryResult result;
  int callCount = 0;
  List<Trade>? lastTrades;
  DateTime? lastEvaluatedAt;

  _FakeTradeHistoryEngine(this.result);

  @override
  TradeHistoryResult calculate({
    required List<Trade> trades,
    DateTime? evaluatedAt,
  }) {
    callCount += 1;
    lastTrades = trades;
    lastEvaluatedAt = evaluatedAt;
    return result;
  }
}

ExecuteTradeHistoryFailureCode _applicationCode(
  ExecuteTradeHistoryResult result,
) {
  expect(result, isA<ExecuteTradeHistoryApplicationFailed>());
  return (result as ExecuteTradeHistoryApplicationFailed).failure.code;
}

TradingFailureCode _domainCode(ExecuteTradeHistoryResult result) {
  expect(result, isA<ExecuteTradeHistoryDomainRejected>());
  return (result as ExecuteTradeHistoryDomainRejected).failure.code;
}

TradeHistorySnapshot _emptySnapshot(DateTime evaluatedAt) {
  final result = const TradeHistoryEngine().calculate(
    trades: const [],
    evaluatedAt: evaluatedAt,
  );
  expect(result, isA<TradeHistorySuccess>());
  return (result as TradeHistorySuccess).snapshot;
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
