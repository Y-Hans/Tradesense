import '../../../core/contracts/market_provider.dart';
import '../../../shared/models/holding.dart';
import '../../../shared/models/market_ticker.dart';
import '../../../shared/models/trade.dart';
import '../../trading/application/execute_buy_contracts.dart';
import '../domain/portfolio_engine.dart';
import '../domain/portfolio_engine_result.dart';
import 'execute_portfolio_contracts.dart';
import 'execute_portfolio_result.dart';

class ExecutePortfolioRequest {
  final String userId;
  final DateTime? evaluatedAt;

  const ExecutePortfolioRequest({
    required this.userId,
    this.evaluatedAt,
  });
}

class ExecutePortfolioUseCase {
  final ExecutePortfolioWalletRepository walletRepository;
  final ExecutePortfolioHoldingRepository holdingRepository;
  final ExecutePortfolioTradeRepository tradeRepository;
  final MarketProvider marketProvider;
  final PortfolioEngine portfolioEngine;
  final ExecutePortfolioClock clock;

  const ExecutePortfolioUseCase({
    required this.walletRepository,
    required this.holdingRepository,
    required this.tradeRepository,
    required this.marketProvider,
    required this.portfolioEngine,
    required this.clock,
  });

  Future<ExecutePortfolioResult> execute(
    ExecutePortfolioRequest request,
  ) async {
    final userId = request.userId.trim();
    if (userId.isEmpty) {
      return const ExecutePortfolioApplicationFailed(
        ExecutePortfolioFailure(
          code: ExecutePortfolioFailureCode.invalidUserContext,
          message: 'Authenticated user id must be supplied.',
        ),
      );
    }

    final walletState = await _loadWallet(userId);
    if (walletState is ExecutePortfolioApplicationFailed) return walletState;
    final persistedWallet = walletState as _LoadedWallet;
    if (persistedWallet.state.userId != userId) {
      return const ExecutePortfolioApplicationFailed(
        ExecutePortfolioFailure(
          code: ExecutePortfolioFailureCode.walletOwnershipMismatch,
          message: 'Loaded wallet does not belong to the requested user.',
        ),
      );
    }

    final holdingsState = await _loadHoldings(userId);
    if (holdingsState is ExecutePortfolioApplicationFailed) {
      return holdingsState;
    }
    final holdings = (holdingsState as _LoadedHoldings).holdings;
    if (holdings.any((holding) => holding.userId != userId)) {
      return const ExecutePortfolioApplicationFailed(
        ExecutePortfolioFailure(
          code: ExecutePortfolioFailureCode.holdingOwnershipMismatch,
          message: 'Loaded holdings must belong to the requested user.',
        ),
      );
    }

    final tradesState = await _loadTrades(userId);
    if (tradesState is ExecutePortfolioApplicationFailed) return tradesState;
    final trades = (tradesState as _LoadedTrades).trades;
    if (trades.any((trade) => trade.userId != userId)) {
      return const ExecutePortfolioApplicationFailed(
        ExecutePortfolioFailure(
          code: ExecutePortfolioFailureCode.tradeOwnershipMismatch,
          message: 'Loaded trades must belong to the requested user.',
        ),
      );
    }

    final orderedHoldings = List<Holding>.of(holdings)..sort(_compareHoldings);
    final orderedTrades = List<Trade>.of(trades)..sort(_compareTrades);
    final tickerSymbols = _uniqueHoldingSymbols(orderedHoldings);
    final tickersState = await _loadTickers(tickerSymbols);
    if (tickersState is ExecutePortfolioApplicationFailed) {
      return tickersState;
    }
    final tickers = (tickersState as _LoadedTickers).tickers;
    final evaluatedAt = request.evaluatedAt ?? clock.now();

    final portfolioResult = portfolioEngine.calculate(
      wallet: persistedWallet.state.wallet,
      holdings: orderedHoldings,
      tickers: tickers,
      trades: orderedTrades,
      evaluatedAt: evaluatedAt,
    );

    if (portfolioResult is PortfolioEngineRejected) {
      return ExecutePortfolioDomainRejected(portfolioResult.failure);
    }

    final success = portfolioResult as PortfolioEngineSuccess;
    // Future PortfolioViewed event publishing belongs here after success.
    return ExecutePortfolioSuccess(snapshot: success.snapshot);
  }

  Future<Object> _loadWallet(String userId) async {
    try {
      final wallet = await walletRepository.getWalletForUser(userId);
      if (wallet == null) {
        return const ExecutePortfolioApplicationFailed(
          ExecutePortfolioFailure(
            code: ExecutePortfolioFailureCode.walletNotFound,
            message: 'No initialized virtual wallet exists for this user.',
          ),
        );
      }
      return _LoadedWallet(wallet);
    } catch (_) {
      return const ExecutePortfolioApplicationFailed(
        ExecutePortfolioFailure(
          code: ExecutePortfolioFailureCode.walletRepositoryFailure,
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
      return const ExecutePortfolioApplicationFailed(
        ExecutePortfolioFailure(
          code: ExecutePortfolioFailureCode.holdingsRepositoryFailure,
          message: 'Unable to load current asset holdings.',
        ),
      );
    }
  }

  Future<Object> _loadTrades(String userId) async {
    try {
      final trades = await tradeRepository.getTradesForUser(userId);
      return _LoadedTrades(List<Trade>.of(trades));
    } catch (_) {
      return const ExecutePortfolioApplicationFailed(
        ExecutePortfolioFailure(
          code: ExecutePortfolioFailureCode.tradesRepositoryFailure,
          message: 'Unable to load trade history.',
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
      return const ExecutePortfolioApplicationFailed(
        ExecutePortfolioFailure(
          code: ExecutePortfolioFailureCode.marketTickerUnavailable,
          message: 'No current ticker is available for a held asset.',
        ),
      );
    } catch (_) {
      return const ExecutePortfolioApplicationFailed(
        ExecutePortfolioFailure(
          code: ExecutePortfolioFailureCode.marketRepositoryFailure,
          message: 'Unable to load current market ticker data.',
        ),
      );
    }
  }

  List<String> _uniqueHoldingSymbols(List<Holding> holdings) {
    final symbols = <String>{};
    for (final holding in holdings) {
      final symbol = _normalizeSymbol(holding.symbol);
      if (symbol.isNotEmpty) symbols.add(symbol);
    }
    return List<String>.unmodifiable(symbols);
  }

  int _compareHoldings(Holding left, Holding right) {
    final symbolComparison =
        _normalizeSymbol(left.symbol).compareTo(_normalizeSymbol(right.symbol));
    if (symbolComparison != 0) return symbolComparison;
    return left.id.compareTo(right.id);
  }

  int _compareTrades(Trade left, Trade right) {
    final timestampComparison = left.timestamp.compareTo(right.timestamp);
    if (timestampComparison != 0) return timestampComparison;
    return left.id.compareTo(right.id);
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

class _LoadedTrades {
  final List<Trade> trades;

  const _LoadedTrades(this.trades);
}

class _LoadedTickers {
  final List<MarketTicker> tickers;

  const _LoadedTickers(this.tickers);
}
