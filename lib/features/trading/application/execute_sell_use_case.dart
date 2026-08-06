import '../../../core/contracts/market_provider.dart';
import '../../../shared/models/holding.dart';
import '../../../shared/models/market_ticker.dart';
import '../domain/sell_trade_result.dart';
import '../domain/stop_loss_evaluation_result.dart';
import '../domain/trading_domain_service.dart';
import 'execute_buy_contracts.dart';
import 'execute_sell_contracts.dart';
import 'execute_sell_result.dart';
import 'trading_event_publisher.dart';
import 'trading_events.dart';

class ExecuteSellRequest {
  static const String manualReason = 'MANUAL';

  final String userId;
  final String assetSymbol;
  final double quantity;
  final int disciplineScoreAtTrade;
  final int riskScoreAtTrade;
  final String sellReason;
  final SellExecutionRequest? executionRequest;
  final DateTime? evaluatedAt;
  final DateTime? executedAt;
  final String? tradeId;

  const ExecuteSellRequest({
    required this.userId,
    required this.assetSymbol,
    required this.quantity,
    required this.disciplineScoreAtTrade,
    required this.riskScoreAtTrade,
    this.sellReason = manualReason,
    this.executionRequest,
    this.evaluatedAt,
    this.executedAt,
    this.tradeId,
  });

  factory ExecuteSellRequest.fromStopLoss({
    required String userId,
    required SellExecutionRequest executionRequest,
    required int disciplineScoreAtTrade,
    required int riskScoreAtTrade,
    DateTime? executedAt,
    String? tradeId,
  }) {
    return ExecuteSellRequest(
      userId: userId,
      assetSymbol: executionRequest.assetSymbol,
      quantity: executionRequest.quantity,
      disciplineScoreAtTrade: disciplineScoreAtTrade,
      riskScoreAtTrade: riskScoreAtTrade,
      sellReason: executionRequest.reason,
      executionRequest: executionRequest,
      evaluatedAt: executionRequest.evaluatedAt,
      executedAt: executedAt,
      tradeId: tradeId,
    );
  }
}

class ExecuteSellUseCase {
  final ExecuteSellWalletRepository walletRepository;
  final ExecuteSellHoldingRepository holdingRepository;
  final MarketProvider marketProvider;
  final TradingTransactionRepository transactionRepository;
  final TradingDomainService tradingDomainService;
  final ExecuteSellClock clock;
  final ExecuteSellIdGenerator idGenerator;
  final TradingEventPublisher eventPublisher;
  final TradingCompletedTradeCountProvider? completedTradeCountProvider;

  const ExecuteSellUseCase({
    required this.walletRepository,
    required this.holdingRepository,
    required this.marketProvider,
    required this.transactionRepository,
    required this.tradingDomainService,
    required this.clock,
    required this.idGenerator,
    this.eventPublisher = const NoOpTradingEventPublisher(),
    this.completedTradeCountProvider,
  });

  Future<ExecuteSellResult> execute(ExecuteSellRequest request) async {
    final userId = request.userId.trim();
    if (userId.isEmpty) {
      return const ExecuteSellApplicationFailed(
        ExecuteSellFailure(
          code: ExecuteSellFailureCode.invalidUserContext,
          message: 'Authenticated user id must be supplied.',
        ),
      );
    }

    final symbol = _normalizeSymbol(
      request.executionRequest?.assetSymbol ?? request.assetSymbol,
    );
    if (symbol.isEmpty) {
      return const ExecuteSellApplicationFailed(
        ExecuteSellFailure(
          code: ExecuteSellFailureCode.invalidSellRequest,
          message: 'Asset symbol must be supplied for SELL execution.',
        ),
      );
    }

    final walletState = await _loadWallet(userId);
    if (walletState is ExecuteSellApplicationFailed) return walletState;
    final persistedWallet = walletState as _LoadedWallet;
    if (persistedWallet.state.userId != userId) {
      return const ExecuteSellApplicationFailed(
        ExecuteSellFailure(
          code: ExecuteSellFailureCode.walletOwnershipMismatch,
          message: 'Loaded wallet does not belong to the requested user.',
        ),
      );
    }

    final holdingState = await _loadHolding(userId, symbol);
    if (holdingState is ExecuteSellApplicationFailed) return holdingState;
    final existingHolding = (holdingState as _LoadedHolding).holding;
    if (existingHolding == null) {
      return const ExecuteSellApplicationFailed(
        ExecuteSellFailure(
          code: ExecuteSellFailureCode.holdingNotFound,
          message: 'No asset holding exists for this SELL request.',
        ),
      );
    }
    if (existingHolding.userId != userId) {
      return const ExecuteSellApplicationFailed(
        ExecuteSellFailure(
          code: ExecuteSellFailureCode.holdingOwnershipMismatch,
          message: 'Loaded holding does not belong to the requested user.',
        ),
      );
    }

    final tickerState = await _loadTicker(symbol);
    if (tickerState is ExecuteSellApplicationFailed) return tickerState;
    final ticker = (tickerState as _LoadedTicker).ticker;

    final evaluatedAt = request.evaluatedAt ??
        request.executionRequest?.evaluatedAt ??
        clock.now();
    final executedAt = request.executedAt ?? evaluatedAt;
    final tradeId = _resolveTradeId(request);
    if (tradeId is ExecuteSellApplicationFailed) return tradeId;
    final sellReason = _resolveSellReason(request);

    final sellResult = tradingDomainService.calculateSell(
      wallet: persistedWallet.state.wallet,
      walletUserId: persistedWallet.state.userId,
      existingHolding: existingHolding,
      ticker: ticker,
      sellQuantity: request.executionRequest?.quantity ?? request.quantity,
      executedAt: executedAt,
      evaluatedAt: evaluatedAt,
      tradeId: (tradeId as _ResolvedId).id,
      userId: userId,
      disciplineScoreAtTrade: request.disciplineScoreAtTrade,
      riskScoreAtTrade: request.riskScoreAtTrade,
    );

    if (sellResult is SellTradeRejected) {
      return ExecuteSellDomainRejected(sellResult.failure);
    }

    final success = sellResult as SellTradeSuccess;
    final SellTransactionCommitResult commitResult;
    try {
      commitResult = await transactionRepository.commitSell(
        userId: userId,
        updatedWallet: success.updatedWallet,
        updatedHolding: success.updatedHolding,
        trade: success.trade,
        expectedPreviousWalletBalanceInr: success.previousWalletBalanceInr,
        expectedPreviousHoldingQuantity: success.previousHoldingQuantity,
        expectedWalletVersion: persistedWallet.state.version,
        executedAt: executedAt,
        sellReason: sellReason,
        sourceStopLossOrderId: request.executionRequest?.orderId,
      );
    } catch (_) {
      return const ExecuteSellApplicationFailed(
        ExecuteSellFailure(
          code: ExecuteSellFailureCode.transactionPersistenceFailure,
          message: 'Atomic SELL persistence failed.',
        ),
      );
    }

    if (commitResult is SellTransactionCommitFailure) {
      return ExecuteSellApplicationFailed(
        _mapTransactionFailure(commitResult.failure),
      );
    }

    final confirmation = commitResult as SellTransactionCommitSuccess;
    _publishSellEvents(
      userId: userId,
      success: success,
      commitConfirmation: confirmation,
    );

    return ExecuteSellSuccess(
      updatedWallet: success.updatedWallet,
      updatedHolding: success.updatedHolding,
      trade: success.trade,
      executionTicker: ticker,
      domainDetails: success,
      commitConfirmation: confirmation,
      sellReason: sellReason,
      sourceStopLossOrderId: request.executionRequest?.orderId,
    );
  }

  Future<Object> _loadWallet(String userId) async {
    try {
      final wallet = await walletRepository.getWalletForUser(userId);
      if (wallet == null) {
        return const ExecuteSellApplicationFailed(
          ExecuteSellFailure(
            code: ExecuteSellFailureCode.walletNotFound,
            message: 'No initialized virtual wallet exists for this user.',
          ),
        );
      }
      return _LoadedWallet(wallet);
    } catch (_) {
      return const ExecuteSellApplicationFailed(
        ExecuteSellFailure(
          code: ExecuteSellFailureCode.walletRepositoryFailure,
          message: 'Unable to load the current virtual wallet.',
        ),
      );
    }
  }

  Future<Object> _loadHolding(String userId, String symbol) async {
    try {
      final holding = await holdingRepository.getHoldingForUserAsset(
        userId: userId,
        symbol: symbol,
      );
      return _LoadedHolding(holding);
    } catch (_) {
      return const ExecuteSellApplicationFailed(
        ExecuteSellFailure(
          code: ExecuteSellFailureCode.holdingRepositoryFailure,
          message: 'Unable to load the current asset holding.',
        ),
      );
    }
  }

  Future<Object> _loadTicker(String symbol) async {
    try {
      final ticker = await marketProvider.getTicker(symbol);
      return _LoadedTicker(ticker);
    } on MarketTickerUnavailableException {
      return const ExecuteSellApplicationFailed(
        ExecuteSellFailure(
          code: ExecuteSellFailureCode.marketTickerUnavailable,
          message: 'No current ticker is available for the selected asset.',
        ),
      );
    } catch (_) {
      return const ExecuteSellApplicationFailed(
        ExecuteSellFailure(
          code: ExecuteSellFailureCode.marketRepositoryFailure,
          message: 'Unable to load current market ticker data.',
        ),
      );
    }
  }

  Object _resolveTradeId(ExecuteSellRequest request) {
    final supplied = request.tradeId?.trim();
    if (supplied != null && supplied.isNotEmpty) {
      return _ResolvedId(supplied);
    }
    try {
      final generated = idGenerator.nextTradeId().trim();
      if (generated.isEmpty) throw StateError('Blank trade id');
      return _ResolvedId(generated);
    } catch (_) {
      return const ExecuteSellApplicationFailed(
        ExecuteSellFailure(
          code: ExecuteSellFailureCode.idGenerationFailure,
          message: 'Unable to generate a trade identifier.',
        ),
      );
    }
  }

  String _resolveSellReason(ExecuteSellRequest request) {
    final executionReason = request.executionRequest?.reason.trim();
    if (executionReason != null && executionReason.isNotEmpty) {
      return executionReason;
    }
    final supplied = request.sellReason.trim();
    if (supplied.isNotEmpty) return supplied;
    return ExecuteSellRequest.manualReason;
  }

  ExecuteSellFailure _mapTransactionFailure(SellTransactionFailure failure) {
    switch (failure.code) {
      case SellTransactionFailureCode.persistenceFailure:
        return ExecuteSellFailure(
          code: ExecuteSellFailureCode.transactionPersistenceFailure,
          message: failure.message,
        );
      case SellTransactionFailureCode.concurrencyConflict:
        return ExecuteSellFailure(
          code: ExecuteSellFailureCode.concurrencyConflict,
          message: failure.message,
        );
    }
  }

  void _publishSellEvents({
    required String userId,
    required SellTradeSuccess success,
    required SellTransactionCommitSuccess commitConfirmation,
  }) {
    final realizedProfitLossInr = success.realizedProfitLossInr;
    if (realizedProfitLossInr > 0) {
      eventPublisher.publish(
        FirstProfitableTradeCompleted(
          userId: userId,
          occurredAt: commitConfirmation.committedAt,
          tradeId: success.trade.id,
          assetSymbol: success.trade.symbol,
          realizedProfitLossInr: realizedProfitLossInr,
        ),
      );
    } else if (realizedProfitLossInr < 0) {
      eventPublisher.publish(
        FirstLosingTradeCompleted(
          userId: userId,
          occurredAt: commitConfirmation.committedAt,
          tradeId: success.trade.id,
          assetSymbol: success.trade.symbol,
          realizedProfitLossInr: realizedProfitLossInr,
        ),
      );
    }

    switch (_completedTradeCountFor(userId)) {
      case 5:
        eventPublisher.publish(
          FiveTradesCompleted(
            userId: userId,
            occurredAt: commitConfirmation.committedAt,
          ),
        );
      case 10:
        eventPublisher.publish(
          TenTradesCompleted(
            userId: userId,
            occurredAt: commitConfirmation.committedAt,
          ),
        );
    }
  }

  int? _completedTradeCountFor(String userId) {
    final provider = completedTradeCountProvider ??
        (transactionRepository is TradingCompletedTradeCountProvider
            ? transactionRepository as TradingCompletedTradeCountProvider
            : null);
    if (provider == null) return null;
    try {
      return provider.completedTradeCountForUser(userId);
    } catch (_) {
      return null;
    }
  }

  String _normalizeSymbol(String symbol) => symbol.trim().toUpperCase();
}

class _LoadedWallet {
  final PersistedVirtualWallet state;

  const _LoadedWallet(this.state);
}

class _LoadedHolding {
  final Holding? holding;

  const _LoadedHolding(this.holding);
}

class _LoadedTicker {
  final MarketTicker ticker;

  const _LoadedTicker(this.ticker);
}

class _ResolvedId {
  final String id;

  const _ResolvedId(this.id);
}
