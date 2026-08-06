import 'package:flutter/foundation.dart';

enum TradingFailureCode {
  invalidAsset,
  unsupportedAsset,
  invalidBuyAmount,
  invalidSellQuantity,
  invalidWallet,
  walletOwnershipMismatch,
  insufficientFunds,
  missingHolding,
  insufficientHoldings,
  invalidMarketPrice,
  mismatchedTicker,
  staleTicker,
  invalidExistingHolding,
  mismatchedHolding,
  holdingOwnershipMismatch,
  invalidTradeMetadata,
}

@immutable
class TradingFailure {
  final TradingFailureCode code;
  final String message;

  const TradingFailure({
    required this.code,
    required this.message,
  });
}
