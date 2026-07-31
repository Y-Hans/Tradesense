import 'package:flutter/foundation.dart';

import '../domain/trade_history_result.dart';
import '../domain/trading_failure.dart';

sealed class ExecuteTradeHistoryResult {
  const ExecuteTradeHistoryResult();

  bool get isSuccess => this is ExecuteTradeHistorySuccess;
}

@immutable
class ExecuteTradeHistorySuccess extends ExecuteTradeHistoryResult {
  final TradeHistorySnapshot snapshot;
  final DateTime evaluatedAt;

  const ExecuteTradeHistorySuccess({
    required this.snapshot,
    required this.evaluatedAt,
  });
}

@immutable
class ExecuteTradeHistoryDomainRejected extends ExecuteTradeHistoryResult {
  final TradingFailure failure;

  const ExecuteTradeHistoryDomainRejected(this.failure);
}

@immutable
class ExecuteTradeHistoryApplicationFailed extends ExecuteTradeHistoryResult {
  final ExecuteTradeHistoryFailure failure;

  const ExecuteTradeHistoryApplicationFailed(this.failure);
}

enum ExecuteTradeHistoryFailureCode {
  invalidUserContext,
  walletNotFound,
  walletOwnershipMismatch,
  walletRepositoryFailure,
  tradeOwnershipMismatch,
  tradesRepositoryFailure,
  malformedRepositoryData,
}

@immutable
class ExecuteTradeHistoryFailure {
  final ExecuteTradeHistoryFailureCode code;
  final String message;

  const ExecuteTradeHistoryFailure({
    required this.code,
    required this.message,
  });
}
