import 'package:flutter/foundation.dart';

import '../../../shared/models/holding.dart';
import '../../../shared/models/market_ticker.dart';
import '../../../shared/models/trade.dart';
import '../../../shared/models/virtual_wallet.dart';
import '../domain/sell_trade_result.dart';
import '../domain/trading_failure.dart';
import 'execute_buy_contracts.dart';

sealed class ExecuteSellResult {
  const ExecuteSellResult();

  bool get isSuccess => this is ExecuteSellSuccess;
}

@immutable
class ExecuteSellSuccess extends ExecuteSellResult {
  final VirtualWallet updatedWallet;
  final Holding updatedHolding;
  final Trade trade;
  final MarketTicker executionTicker;
  final SellTradeSuccess domainDetails;
  final SellTransactionCommitSuccess commitConfirmation;
  final String sellReason;
  final String? sourceStopLossOrderId;

  const ExecuteSellSuccess({
    required this.updatedWallet,
    required this.updatedHolding,
    required this.trade,
    required this.executionTicker,
    required this.domainDetails,
    required this.commitConfirmation,
    required this.sellReason,
    this.sourceStopLossOrderId,
  });
}

@immutable
class ExecuteSellDomainRejected extends ExecuteSellResult {
  final TradingFailure failure;

  const ExecuteSellDomainRejected(this.failure);
}

@immutable
class ExecuteSellApplicationFailed extends ExecuteSellResult {
  final ExecuteSellFailure failure;

  const ExecuteSellApplicationFailed(this.failure);
}

enum ExecuteSellFailureCode {
  invalidUserContext,
  invalidSellRequest,
  walletNotFound,
  walletOwnershipMismatch,
  walletRepositoryFailure,
  holdingNotFound,
  holdingOwnershipMismatch,
  holdingRepositoryFailure,
  marketTickerUnavailable,
  marketRepositoryFailure,
  transactionPersistenceFailure,
  concurrencyConflict,
  idGenerationFailure,
}

@immutable
class ExecuteSellFailure {
  final ExecuteSellFailureCode code;
  final String message;

  const ExecuteSellFailure({
    required this.code,
    required this.message,
  });
}
