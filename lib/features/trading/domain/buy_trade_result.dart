import 'package:flutter/foundation.dart';

import '../../../shared/models/holding.dart';
import '../../../shared/models/trade.dart';
import '../../../shared/models/virtual_wallet.dart';
import 'trading_failure.dart';

sealed class BuyTradeResult {
  const BuyTradeResult();

  bool get isSuccess => this is BuyTradeSuccess;
  bool get isFailure => this is BuyTradeRejected;
}

@immutable
class BuyTradeSuccess extends BuyTradeResult {
  final VirtualWallet updatedWallet;
  final Holding updatedHolding;
  final Trade trade;
  final double amountSpentInr;
  final double purchasedQuantity;
  final double executionPriceInr;
  final double previousWalletBalanceInr;
  final double newWalletBalanceInr;
  final double previousHoldingQuantity;
  final double newHoldingQuantity;
  final double previousCostBasisInr;
  final double newCostBasisInr;
  final double previousAverageEntryPriceInr;
  final double newAverageEntryPriceInr;

  const BuyTradeSuccess({
    required this.updatedWallet,
    required this.updatedHolding,
    required this.trade,
    required this.amountSpentInr,
    required this.purchasedQuantity,
    required this.executionPriceInr,
    required this.previousWalletBalanceInr,
    required this.newWalletBalanceInr,
    required this.previousHoldingQuantity,
    required this.newHoldingQuantity,
    required this.previousCostBasisInr,
    required this.newCostBasisInr,
    required this.previousAverageEntryPriceInr,
    required this.newAverageEntryPriceInr,
  });
}

@immutable
class BuyTradeRejected extends BuyTradeResult {
  final TradingFailure failure;

  const BuyTradeRejected(this.failure);
}
