import 'package:flutter/foundation.dart';

import '../../../shared/models/holding.dart';
import '../../../shared/models/trade.dart';
import '../../../shared/models/virtual_wallet.dart';
import 'trading_failure.dart';

sealed class SellTradeResult {
  const SellTradeResult();

  bool get isSuccess => this is SellTradeSuccess;
  bool get isFailure => this is SellTradeRejected;
}

@immutable
class SellTradeSuccess extends SellTradeResult {
  final VirtualWallet updatedWallet;
  final Holding updatedHolding;
  final Trade trade;
  final double saleProceedsInr;
  final double soldQuantity;
  final double executionPriceInr;
  final double realizedProfitLossInr;
  final double previousWalletBalanceInr;
  final double newWalletBalanceInr;
  final double previousHoldingQuantity;
  final double newHoldingQuantity;
  final double previousCostBasisInr;
  final double removedCostBasisInr;
  final double remainingCostBasisInr;
  final double previousAverageEntryPriceInr;
  final double newAverageEntryPriceInr;

  const SellTradeSuccess({
    required this.updatedWallet,
    required this.updatedHolding,
    required this.trade,
    required this.saleProceedsInr,
    required this.soldQuantity,
    required this.executionPriceInr,
    required this.realizedProfitLossInr,
    required this.previousWalletBalanceInr,
    required this.newWalletBalanceInr,
    required this.previousHoldingQuantity,
    required this.newHoldingQuantity,
    required this.previousCostBasisInr,
    required this.removedCostBasisInr,
    required this.remainingCostBasisInr,
    required this.previousAverageEntryPriceInr,
    required this.newAverageEntryPriceInr,
  });
}

@immutable
class SellTradeRejected extends SellTradeResult {
  final TradingFailure failure;

  const SellTradeRejected(this.failure);
}
