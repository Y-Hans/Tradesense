import 'package:flutter/foundation.dart';

enum TradingFailureCode {
  invalidAsset,
  unsupportedAsset,
  invalidBuyAmount,
  invalidWallet,
  insufficientFunds,
  invalidMarketPrice,
  mismatchedTicker,
  staleTicker,
  invalidExistingHolding,
  mismatchedHolding,
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
