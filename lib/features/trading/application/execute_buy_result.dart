import 'package:flutter/foundation.dart';

import '../../../shared/models/holding.dart';
import '../../../shared/models/market_ticker.dart';
import '../../../shared/models/trade.dart';
import '../../../shared/models/virtual_wallet.dart';
import '../domain/buy_trade_result.dart';
import '../domain/trading_failure.dart';
import 'execute_buy_contracts.dart';

sealed class ExecuteBuyResult {
  const ExecuteBuyResult();

  bool get isSuccess => this is ExecuteBuySuccess;
}

@immutable
class ExecuteBuySuccess extends ExecuteBuyResult {
  final VirtualWallet updatedWallet;
  final Holding updatedHolding;
  final Trade trade;
  final MarketTicker executionTicker;
  final BuyTradeSuccess domainDetails;
  final BuyTransactionCommitSuccess commitConfirmation;

  const ExecuteBuySuccess({
    required this.updatedWallet,
    required this.updatedHolding,
    required this.trade,
    required this.executionTicker,
    required this.domainDetails,
    required this.commitConfirmation,
  });
}

@immutable
class ExecuteBuyDomainRejected extends ExecuteBuyResult {
  final TradingFailure failure;

  const ExecuteBuyDomainRejected(this.failure);
}

@immutable
class ExecuteBuyApplicationFailed extends ExecuteBuyResult {
  final ExecuteBuyFailure failure;

  const ExecuteBuyApplicationFailed(this.failure);
}

enum ExecuteBuyFailureCode {
  invalidUserContext,
  walletNotFound,
  walletOwnershipMismatch,
  walletRepositoryFailure,
  holdingOwnershipMismatch,
  holdingRepositoryFailure,
  marketTickerUnavailable,
  marketRepositoryFailure,
  transactionPersistenceFailure,
  concurrencyConflict,
  idGenerationFailure,
}

@immutable
class ExecuteBuyFailure {
  final ExecuteBuyFailureCode code;
  final String message;

  const ExecuteBuyFailure({
    required this.code,
    required this.message,
  });
}
