import '../../../core/contracts/market_provider.dart';
import '../../../shared/models/holding.dart';
import '../../../shared/models/market_ticker.dart';
import '../../../shared/models/stop_loss_order.dart';
import '../domain/stop_loss_engine.dart';
import 'execute_buy_contracts.dart';
import 'execute_sell_result.dart';
import 'execute_sell_use_case.dart';
import 'execute_stop_loss_contracts.dart';
import 'execute_stop_loss_result.dart';
import 'trading_event_publisher.dart';
import 'trading_events.dart';

class ExecuteStopLossRequest {
  final String userId;
  final int disciplineScoreAtTrade;
  final int riskScoreAtTrade;
  final DateTime? evaluatedAt;

  const ExecuteStopLossRequest({
    required this.userId,
    required this.disciplineScoreAtTrade,
    required this.riskScoreAtTrade,
    this.evaluatedAt,
  });
}

class ExecuteStopLossUseCase {
  final ExecuteStopLossWalletRepository walletRepository;
  final ExecuteStopLossHoldingRepository holdingRepository;
  final ExecuteStopLossOrderRepository stopLossOrderRepository;
  final MarketProvider marketProvider;
  final StopLossEngine stopLossEngine;
  final ExecuteSellUseCase executeSellUseCase;
  final ExecuteStopLossClock clock;
  final TradingEventPublisher eventPublisher;

  const ExecuteStopLossUseCase({
    required this.walletRepository,
    required this.holdingRepository,
    required this.stopLossOrderRepository,
    required this.marketProvider,
    required this.stopLossEngine,
    required this.executeSellUseCase,
    required this.clock,
    this.eventPublisher = const NoOpTradingEventPublisher(),
  });

  Future<ExecuteStopLossResult> execute(
    ExecuteStopLossRequest request,
  ) async {
    final userId = request.userId.trim();
    if (userId.isEmpty) {
      return ExecuteStopLossApplicationFailed(
        const ExecuteStopLossFailure(
          code: ExecuteStopLossFailureCode.invalidUserContext,
          message: 'Authenticated user id must be supplied.',
        ),
      );
    }

    final walletState = await _loadWallet(userId);
    if (walletState is ExecuteStopLossApplicationFailed) return walletState;
    final persistedWallet = walletState as _LoadedWallet;
    if (persistedWallet.state.userId != userId) {
      return ExecuteStopLossApplicationFailed(
        const ExecuteStopLossFailure(
          code: ExecuteStopLossFailureCode.walletOwnershipMismatch,
          message: 'Loaded wallet does not belong to the requested user.',
        ),
      );
    }

    final holdingsState = await _loadHoldings(userId);
    if (holdingsState is ExecuteStopLossApplicationFailed) {
      return holdingsState;
    }
    final holdings = (holdingsState as _LoadedHoldings).holdings;
    if (holdings.any((holding) => holding.userId != userId)) {
      return ExecuteStopLossApplicationFailed(
        const ExecuteStopLossFailure(
          code: ExecuteStopLossFailureCode.holdingOwnershipMismatch,
          message: 'Loaded holdings must belong to the requested user.',
        ),
      );
    }

    final ordersState = await _loadActiveStopLossOrders(userId);
    if (ordersState is ExecuteStopLossApplicationFailed) return ordersState;
    final orders = (ordersState as _LoadedStopLossOrders).orders;
    if (orders.any((order) => order.userId.trim() != userId)) {
      return ExecuteStopLossApplicationFailed(
        const ExecuteStopLossFailure(
          code: ExecuteStopLossFailureCode.stopLossOrderOwnershipMismatch,
          message: 'Loaded stop-loss orders must belong to the requested user.',
        ),
      );
    }
    if (orders.any((order) => order.status != StopLossStatus.active)) {
      return ExecuteStopLossApplicationFailed(
        const ExecuteStopLossFailure(
          code: ExecuteStopLossFailureCode.malformedRepositoryData,
          message: 'Active stop-loss lookup returned non-active orders.',
        ),
      );
    }

    final orderedHoldings = List<Holding>.of(holdings)..sort(_compareHoldings);
    final orderedOrders = List<StopLossOrder>.of(orders)..sort(_compareOrders);
    final tickerSymbols = _tickerSymbolsForEvaluation(
      orders: orderedOrders,
      holdings: orderedHoldings,
    );
    final tickersState = await _loadTickers(tickerSymbols);
    if (tickersState is ExecuteStopLossApplicationFailed) {
      return tickersState;
    }
    final tickers = (tickersState as _LoadedTickers).tickers;
    final evaluatedAt = request.evaluatedAt ?? clock.now();

    final evaluation = stopLossEngine.evaluate(
      orders: orderedOrders,
      holdings: orderedHoldings,
      tickers: tickers,
      evaluatedAt: evaluatedAt,
    );

    final executedSells = <ExecuteStopLossExecutedSell>[];
    for (final sellRequest in evaluation.sellRequests) {
      final sellResult = await executeSellUseCase.execute(
        ExecuteSellRequest.fromStopLoss(
          userId: userId,
          executionRequest: sellRequest,
          disciplineScoreAtTrade: request.disciplineScoreAtTrade,
          riskScoreAtTrade: request.riskScoreAtTrade,
          executedAt: evaluation.evaluatedAt,
        ),
      );
      if (sellResult is! ExecuteSellSuccess) {
        return ExecuteStopLossApplicationFailed(
          const ExecuteStopLossFailure(
            code: ExecuteStopLossFailureCode.executeSellFailure,
            message: 'Automatic SELL execution failed for a triggered order.',
          ),
          failedSellRequest: sellRequest,
          failedSellResult: sellResult,
          executedSellsBeforeFailure: executedSells,
        );
      }
      executedSells.add(
        ExecuteStopLossExecutedSell(
          sellRequest: sellRequest,
          sellResult: sellResult,
        ),
      );
    }

    final success = ExecuteStopLossSuccess(
      evaluation: evaluation,
      executedSells: executedSells,
    );
    _publishStopLossEvents(userId: userId, success: success);
    return success;
  }

  Future<Object> _loadWallet(String userId) async {
    try {
      final wallet = await walletRepository.getWalletForUser(userId);
      if (wallet == null) {
        return ExecuteStopLossApplicationFailed(
          const ExecuteStopLossFailure(
            code: ExecuteStopLossFailureCode.walletNotFound,
            message: 'No initialized virtual wallet exists for this user.',
          ),
        );
      }
      return _LoadedWallet(wallet);
    } catch (_) {
      return ExecuteStopLossApplicationFailed(
        const ExecuteStopLossFailure(
          code: ExecuteStopLossFailureCode.walletRepositoryFailure,
          message: 'Unable to load the current virtual wallet.',
        ),
      );
    }
  }

  Future<Object> _loadHoldings(String userId) async {
    try {
      final holdings = await holdingRepository.getHoldingsForUser(userId);
      return _LoadedHoldings(List<Holding>.of(holdings));
    } catch (_) {
      return ExecuteStopLossApplicationFailed(
        const ExecuteStopLossFailure(
          code: ExecuteStopLossFailureCode.holdingsRepositoryFailure,
          message: 'Unable to load current asset holdings.',
        ),
      );
    }
  }

  Future<Object> _loadActiveStopLossOrders(String userId) async {
    try {
      final orders =
          await stopLossOrderRepository.getActiveStopLossOrdersForUser(userId);
      return _LoadedStopLossOrders(List<StopLossOrder>.of(orders));
    } catch (_) {
      return ExecuteStopLossApplicationFailed(
        const ExecuteStopLossFailure(
          code: ExecuteStopLossFailureCode.stopLossOrderRepositoryFailure,
          message: 'Unable to load active stop-loss orders.',
        ),
      );
    }
  }

  Future<Object> _loadTickers(List<String> symbols) async {
    final tickers = <MarketTicker>[];
    try {
      for (final symbol in symbols) {
        tickers.add(await marketProvider.getTicker(symbol));
      }
      return _LoadedTickers(List<MarketTicker>.unmodifiable(tickers));
    } on MarketTickerUnavailableException {
      return ExecuteStopLossApplicationFailed(
        const ExecuteStopLossFailure(
          code: ExecuteStopLossFailureCode.marketTickerUnavailable,
          message: 'No current ticker is available for stop-loss evaluation.',
        ),
      );
    } catch (_) {
      return ExecuteStopLossApplicationFailed(
        const ExecuteStopLossFailure(
          code: ExecuteStopLossFailureCode.marketRepositoryFailure,
          message: 'Unable to load current market ticker data.',
        ),
      );
    }
  }

  List<String> _tickerSymbolsForEvaluation({
    required List<StopLossOrder> orders,
    required List<Holding> holdings,
  }) {
    final holdingSymbols = <String>{};
    for (final holding in holdings) {
      final symbol = _normalizeSymbol(holding.symbol);
      if (symbol.isNotEmpty) holdingSymbols.add(symbol);
    }

    final symbols = <String>{};
    for (final order in orders) {
      final symbol = _normalizeSymbol(order.symbol);
      if (symbol.isNotEmpty && holdingSymbols.contains(symbol)) {
        symbols.add(symbol);
      }
    }
    return List<String>.unmodifiable(symbols);
  }

  int _compareHoldings(Holding left, Holding right) {
    final symbolComparison =
        _normalizeSymbol(left.symbol).compareTo(_normalizeSymbol(right.symbol));
    if (symbolComparison != 0) return symbolComparison;
    return left.id.compareTo(right.id);
  }

  int _compareOrders(StopLossOrder left, StopLossOrder right) {
    final symbolComparison =
        _normalizeSymbol(left.symbol).compareTo(_normalizeSymbol(right.symbol));
    if (symbolComparison != 0) return symbolComparison;
    return left.id.trim().compareTo(right.id.trim());
  }

  void _publishStopLossEvents({
    required String userId,
    required ExecuteStopLossSuccess success,
  }) {
    for (final executedSell in success.executedSells) {
      final sellRequest = executedSell.sellRequest;
      final sellResult = executedSell.sellResult;
      eventPublisher.publish(
        StopLossTriggered(
          userId: userId,
          occurredAt: success.evaluation.evaluatedAt,
          stopLossOrderId: sellRequest.orderId,
          assetSymbol: sellRequest.assetSymbol,
          quantity: sellRequest.quantity,
          marketPriceInr: sellRequest.marketPriceInr,
          triggerPriceInr: sellRequest.triggerPriceInr,
        ),
      );
      eventPublisher.publish(
        AutomaticSellExecuted(
          userId: userId,
          occurredAt: sellResult.trade.timestamp,
          stopLossOrderId: sellRequest.orderId,
          tradeId: sellResult.trade.id,
          assetSymbol: sellRequest.assetSymbol,
          quantity: sellRequest.quantity,
          proceedsInr: sellResult.domainDetails.saleProceedsInr,
          realizedProfitLossInr: sellResult.domainDetails.realizedProfitLossInr,
        ),
      );
    }
  }

  String _normalizeSymbol(String symbol) => symbol.trim().toUpperCase();
}

class _LoadedWallet {
  final PersistedVirtualWallet state;

  const _LoadedWallet(this.state);
}

class _LoadedHoldings {
  final List<Holding> holdings;

  const _LoadedHoldings(this.holdings);
}

class _LoadedStopLossOrders {
  final List<StopLossOrder> orders;

  const _LoadedStopLossOrders(this.orders);
}

class _LoadedTickers {
  final List<MarketTicker> tickers;

  const _LoadedTickers(this.tickers);
}
