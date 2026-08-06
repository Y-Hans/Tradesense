import 'package:flutter/foundation.dart';

import '../domain/portfolio_engine_result.dart';
import '../../trading/domain/trading_failure.dart';

sealed class ExecutePortfolioResult {
  const ExecutePortfolioResult();

  bool get isSuccess => this is ExecutePortfolioSuccess;
}

@immutable
class ExecutePortfolioSuccess extends ExecutePortfolioResult {
  final PortfolioSnapshot snapshot;

  const ExecutePortfolioSuccess({
    required this.snapshot,
  });
}

@immutable
class ExecutePortfolioDomainRejected extends ExecutePortfolioResult {
  final TradingFailure failure;

  const ExecutePortfolioDomainRejected(this.failure);
}

@immutable
class ExecutePortfolioApplicationFailed extends ExecutePortfolioResult {
  final ExecutePortfolioFailure failure;

  const ExecutePortfolioApplicationFailed(this.failure);
}

enum ExecutePortfolioFailureCode {
  invalidUserContext,
  walletNotFound,
  walletOwnershipMismatch,
  walletRepositoryFailure,
  holdingOwnershipMismatch,
  holdingsRepositoryFailure,
  tradeOwnershipMismatch,
  tradesRepositoryFailure,
  marketTickerUnavailable,
  marketRepositoryFailure,
}

@immutable
class ExecutePortfolioFailure {
  final ExecutePortfolioFailureCode code;
  final String message;

  const ExecutePortfolioFailure({
    required this.code,
    required this.message,
  });
}
