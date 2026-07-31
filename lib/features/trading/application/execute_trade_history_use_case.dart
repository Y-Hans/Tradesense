import '../../../shared/models/trade.dart';
import '../domain/trade_history_engine.dart';
import '../domain/trade_history_result.dart';
import 'execute_buy_contracts.dart';
import 'execute_trade_history_contracts.dart';
import 'execute_trade_history_result.dart';

class ExecuteTradeHistoryRequest {
  final String userId;
  final DateTime? evaluatedAt;

  const ExecuteTradeHistoryRequest({
    required this.userId,
    this.evaluatedAt,
  });
}

class ExecuteTradeHistoryUseCase {
  final ExecuteTradeHistoryWalletRepository walletRepository;
  final ExecuteTradeHistoryTradeRepository tradeRepository;
  final TradeHistoryEngine tradeHistoryEngine;
  final ExecuteTradeHistoryClock clock;

  const ExecuteTradeHistoryUseCase({
    required this.walletRepository,
    required this.tradeRepository,
    required this.tradeHistoryEngine,
    required this.clock,
  });

  Future<ExecuteTradeHistoryResult> execute(
    ExecuteTradeHistoryRequest request,
  ) async {
    final userId = request.userId.trim();
    if (userId.isEmpty) {
      return const ExecuteTradeHistoryApplicationFailed(
        ExecuteTradeHistoryFailure(
          code: ExecuteTradeHistoryFailureCode.invalidUserContext,
          message: 'Authenticated user id must be supplied.',
        ),
      );
    }

    final walletState = await _loadWallet(userId);
    if (walletState is ExecuteTradeHistoryApplicationFailed) {
      return walletState;
    }
    final persistedWallet = walletState as _LoadedWallet;
    if (persistedWallet.state.userId != userId) {
      return const ExecuteTradeHistoryApplicationFailed(
        ExecuteTradeHistoryFailure(
          code: ExecuteTradeHistoryFailureCode.walletOwnershipMismatch,
          message: 'Loaded wallet does not belong to the requested user.',
        ),
      );
    }

    final tradesState = await _loadTrades(userId);
    if (tradesState is ExecuteTradeHistoryApplicationFailed) {
      return tradesState;
    }
    final trades = (tradesState as _LoadedTrades).trades;
    if (trades.any((trade) => trade.userId.trim().isEmpty)) {
      return const ExecuteTradeHistoryApplicationFailed(
        ExecuteTradeHistoryFailure(
          code: ExecuteTradeHistoryFailureCode.malformedRepositoryData,
          message: 'Loaded trades must include an owning user id.',
        ),
      );
    }
    if (trades.any((trade) => trade.userId != userId)) {
      return const ExecuteTradeHistoryApplicationFailed(
        ExecuteTradeHistoryFailure(
          code: ExecuteTradeHistoryFailureCode.tradeOwnershipMismatch,
          message: 'Loaded trades must belong to the requested user.',
        ),
      );
    }

    final orderedTrades = List<Trade>.of(trades)..sort(_compareTrades);
    final evaluatedAt = request.evaluatedAt ?? clock.now();
    final historyResult = tradeHistoryEngine.calculate(
      trades: orderedTrades,
      evaluatedAt: evaluatedAt,
    );

    if (historyResult is TradeHistoryRejected) {
      return ExecuteTradeHistoryDomainRejected(historyResult.failure);
    }

    final success = historyResult as TradeHistorySuccess;
    // Future TradeHistoryViewed event publishing belongs here after success.
    return ExecuteTradeHistorySuccess(
      snapshot: success.snapshot,
      evaluatedAt: evaluatedAt,
    );
  }

  Future<Object> _loadWallet(String userId) async {
    try {
      final wallet = await walletRepository.getWalletForUser(userId);
      if (wallet == null) {
        return const ExecuteTradeHistoryApplicationFailed(
          ExecuteTradeHistoryFailure(
            code: ExecuteTradeHistoryFailureCode.walletNotFound,
            message: 'No initialized virtual wallet exists for this user.',
          ),
        );
      }
      return _LoadedWallet(wallet);
    } catch (_) {
      return const ExecuteTradeHistoryApplicationFailed(
        ExecuteTradeHistoryFailure(
          code: ExecuteTradeHistoryFailureCode.walletRepositoryFailure,
          message: 'Unable to load the current virtual wallet.',
        ),
      );
    }
  }

  Future<Object> _loadTrades(String userId) async {
    try {
      final trades = await tradeRepository.getTradesForUser(userId);
      return _LoadedTrades(List<Trade>.of(trades));
    } catch (_) {
      return const ExecuteTradeHistoryApplicationFailed(
        ExecuteTradeHistoryFailure(
          code: ExecuteTradeHistoryFailureCode.tradesRepositoryFailure,
          message: 'Unable to load trade history.',
        ),
      );
    }
  }

  int _compareTrades(Trade left, Trade right) {
    final timestampComparison = left.timestamp.compareTo(right.timestamp);
    if (timestampComparison != 0) return timestampComparison;
    return left.id.compareTo(right.id);
  }
}

class _LoadedWallet {
  final PersistedVirtualWallet state;

  const _LoadedWallet(this.state);
}

class _LoadedTrades {
  final List<Trade> trades;

  const _LoadedTrades(this.trades);
}
