import '../../../core/contracts/market_provider.dart';
import '../../../shared/models/crypto_asset.dart';
import '../../../shared/models/holding.dart';
import '../../../shared/models/market_ticker.dart';
import '../domain/buy_trade_result.dart';
import '../domain/trading_domain_service.dart';
import 'execute_buy_contracts.dart';
import 'execute_buy_result.dart';
import 'trading_event_publisher.dart';
import 'trading_events.dart';

class ExecuteBuyRequest {
  final String userId;
  final CryptoAsset asset;
  final double buyAmountInr;
  final int disciplineScoreAtTrade;
  final int riskScoreAtTrade;
  final DateTime? evaluatedAt;
  final DateTime? executedAt;
  final String? tradeId;
  final String? holdingId;

  const ExecuteBuyRequest({
    required this.userId,
    required this.asset,
    required this.buyAmountInr,
    required this.disciplineScoreAtTrade,
    required this.riskScoreAtTrade,
    this.evaluatedAt,
    this.executedAt,
    this.tradeId,
    this.holdingId,
  });
}

class ExecuteBuyUseCase {
  final ExecuteBuyWalletRepository walletRepository;
  final ExecuteBuyHoldingRepository holdingRepository;
  final MarketProvider marketProvider;
  final TradingTransactionRepository transactionRepository;
  final TradingDomainService tradingDomainService;
  final ExecuteBuyClock clock;
  final ExecuteBuyIdGenerator idGenerator;
  final TradingEventPublisher eventPublisher;
  final TradingCompletedTradeCountProvider? completedTradeCountProvider;

  const ExecuteBuyUseCase({
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

  Future<ExecuteBuyResult> execute(ExecuteBuyRequest request) async {
    final userId = request.userId.trim();
    if (userId.isEmpty) {
      return const ExecuteBuyApplicationFailed(
        ExecuteBuyFailure(
          code: ExecuteBuyFailureCode.invalidUserContext,
          message: 'Authenticated user id must be supplied.',
        ),
      );
    }

    final walletState = await _loadWallet(userId);
    if (walletState is ExecuteBuyApplicationFailed) return walletState;
    final persistedWallet = walletState as _LoadedWallet;
    if (persistedWallet.state.userId != userId) {
      return const ExecuteBuyApplicationFailed(
        ExecuteBuyFailure(
          code: ExecuteBuyFailureCode.walletOwnershipMismatch,
          message: 'Loaded wallet does not belong to the requested user.',
        ),
      );
    }

    final symbol = _normalizeSymbol(request.asset.symbol);
    final holdingState = await _loadHolding(userId, symbol);
    if (holdingState is ExecuteBuyApplicationFailed) return holdingState;
    final existingHolding = (holdingState as _LoadedHolding).holding;
    if (existingHolding != null && existingHolding.userId != userId) {
      return const ExecuteBuyApplicationFailed(
        ExecuteBuyFailure(
          code: ExecuteBuyFailureCode.holdingOwnershipMismatch,
          message: 'Loaded holding does not belong to the requested user.',
        ),
      );
    }

    final tickerState = await _loadTicker(symbol);
    if (tickerState is ExecuteBuyApplicationFailed) return tickerState;
    final ticker = (tickerState as _LoadedTicker).ticker;

    final evaluatedAt = request.evaluatedAt ?? clock.now();
    final executedAt = request.executedAt ?? evaluatedAt;
    final tradeId = _resolveTradeId(request);
    if (tradeId is ExecuteBuyApplicationFailed) return tradeId;
    final holdingId = _resolveHoldingId(
      request: request,
      userId: userId,
      symbol: symbol,
      existingHolding: existingHolding,
    );
    if (holdingId is ExecuteBuyApplicationFailed) return holdingId;

    final buyResult = tradingDomainService.calculateBuy(
      wallet: persistedWallet.state.wallet,
      asset: request.asset,
      ticker: ticker,
      buyAmountInr: request.buyAmountInr,
      existingHolding: existingHolding,
      executedAt: executedAt,
      evaluatedAt: evaluatedAt,
      tradeId: (tradeId as _ResolvedId).id,
      userId: userId,
      holdingId: (holdingId as _ResolvedId).id,
      disciplineScoreAtTrade: request.disciplineScoreAtTrade,
      riskScoreAtTrade: request.riskScoreAtTrade,
    );

    if (buyResult is BuyTradeRejected) {
      return ExecuteBuyDomainRejected(buyResult.failure);
    }

    final success = buyResult as BuyTradeSuccess;
    final BuyTransactionCommitResult commitResult;
    try {
      commitResult = await transactionRepository.commitBuy(
        userId: userId,
        updatedWallet: success.updatedWallet,
        updatedHolding: success.updatedHolding,
        trade: success.trade,
        expectedPreviousWalletBalanceInr: success.previousWalletBalanceInr,
        expectedWalletVersion: persistedWallet.state.version,
        executedAt: executedAt,
      );
    } catch (_) {
      return const ExecuteBuyApplicationFailed(
        ExecuteBuyFailure(
          code: ExecuteBuyFailureCode.transactionPersistenceFailure,
          message: 'Atomic BUY persistence failed.',
        ),
      );
    }

    if (commitResult is BuyTransactionCommitFailure) {
      return ExecuteBuyApplicationFailed(
        _mapTransactionFailure(commitResult.failure),
      );
    }

    final confirmation = commitResult as BuyTransactionCommitSuccess;
    _publishBuyEvents(
      userId: userId,
      previousHolding: existingHolding,
      success: success,
      commitConfirmation: confirmation,
    );

    return ExecuteBuySuccess(
      updatedWallet: success.updatedWallet,
      updatedHolding: success.updatedHolding,
      trade: success.trade,
      executionTicker: ticker,
      domainDetails: success,
      commitConfirmation: confirmation,
    );
  }

  Future<Object> _loadWallet(String userId) async {
    try {
      final wallet = await walletRepository.getWalletForUser(userId);
      if (wallet == null) {
        return const ExecuteBuyApplicationFailed(
          ExecuteBuyFailure(
            code: ExecuteBuyFailureCode.walletNotFound,
            message: 'No initialized virtual wallet exists for this user.',
          ),
        );
      }
      return _LoadedWallet(wallet);
    } catch (_) {
      return const ExecuteBuyApplicationFailed(
        ExecuteBuyFailure(
          code: ExecuteBuyFailureCode.walletRepositoryFailure,
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
      return const ExecuteBuyApplicationFailed(
        ExecuteBuyFailure(
          code: ExecuteBuyFailureCode.holdingRepositoryFailure,
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
      return const ExecuteBuyApplicationFailed(
        ExecuteBuyFailure(
          code: ExecuteBuyFailureCode.marketTickerUnavailable,
          message: 'No current ticker is available for the selected asset.',
        ),
      );
    } catch (_) {
      return const ExecuteBuyApplicationFailed(
        ExecuteBuyFailure(
          code: ExecuteBuyFailureCode.marketRepositoryFailure,
          message: 'Unable to load current market ticker data.',
        ),
      );
    }
  }

  Object _resolveTradeId(ExecuteBuyRequest request) {
    final supplied = request.tradeId?.trim();
    if (supplied != null && supplied.isNotEmpty) {
      return _ResolvedId(supplied);
    }
    try {
      final generated = idGenerator.nextTradeId().trim();
      if (generated.isEmpty) throw StateError('Blank trade id');
      return _ResolvedId(generated);
    } catch (_) {
      return const ExecuteBuyApplicationFailed(
        ExecuteBuyFailure(
          code: ExecuteBuyFailureCode.idGenerationFailure,
          message: 'Unable to generate a trade identifier.',
        ),
      );
    }
  }

  Object _resolveHoldingId({
    required ExecuteBuyRequest request,
    required String userId,
    required String symbol,
    required Holding? existingHolding,
  }) {
    final existingId = existingHolding?.id.trim();
    if (existingId != null && existingId.isNotEmpty) {
      return _ResolvedId(existingId);
    }
    final supplied = request.holdingId?.trim();
    if (supplied != null && supplied.isNotEmpty) {
      return _ResolvedId(supplied);
    }
    try {
      final generated = idGenerator
          .nextHoldingId(
            userId: userId,
            symbol: symbol,
          )
          .trim();
      if (generated.isEmpty) throw StateError('Blank holding id');
      return _ResolvedId(generated);
    } catch (_) {
      return const ExecuteBuyApplicationFailed(
        ExecuteBuyFailure(
          code: ExecuteBuyFailureCode.idGenerationFailure,
          message: 'Unable to generate a holding identifier.',
        ),
      );
    }
  }

  ExecuteBuyFailure _mapTransactionFailure(BuyTransactionFailure failure) {
    switch (failure.code) {
      case BuyTransactionFailureCode.persistenceFailure:
        return ExecuteBuyFailure(
          code: ExecuteBuyFailureCode.transactionPersistenceFailure,
          message: failure.message,
        );
      case BuyTransactionFailureCode.concurrencyConflict:
        return ExecuteBuyFailure(
          code: ExecuteBuyFailureCode.concurrencyConflict,
          message: failure.message,
        );
    }
  }

  void _publishBuyEvents({
    required String userId,
    required Holding? previousHolding,
    required BuyTradeSuccess success,
    required BuyTransactionCommitSuccess commitConfirmation,
  }) {
    final completedTradeCount = _completedTradeCountFor(userId);
    final isFirstTrade = completedTradeCount == 1 ||
        (completedTradeCount == null && previousHolding == null);
    if (!isFirstTrade) return;

    eventPublisher.publish(
      FirstTradeCompleted(
        userId: userId,
        occurredAt: commitConfirmation.committedAt,
        tradeId: success.trade.id,
        assetSymbol: success.trade.symbol,
        side: success.trade.side,
        totalAmountInr: success.trade.totalAmountInr,
      ),
    );
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
