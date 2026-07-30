import '../../../shared/models/holding.dart';
import '../../../shared/models/trade.dart';
import '../../../shared/models/virtual_wallet.dart';

abstract interface class ExecuteBuyWalletRepository {
  Future<PersistedVirtualWallet?> getWalletForUser(String userId);
}

abstract interface class ExecuteBuyHoldingRepository {
  Future<Holding?> getHoldingForUserAsset({
    required String userId,
    required String symbol,
  });
}

abstract interface class TradingTransactionRepository {
  Future<BuyTransactionCommitResult> commitBuy({
    required String userId,
    required VirtualWallet updatedWallet,
    required Holding updatedHolding,
    required Trade trade,
    required double expectedPreviousWalletBalanceInr,
    String? expectedWalletVersion,
    required DateTime executedAt,
  });

  Future<SellTransactionCommitResult> commitSell({
    required String userId,
    required VirtualWallet updatedWallet,
    required Holding updatedHolding,
    required Trade trade,
    required double expectedPreviousWalletBalanceInr,
    required double expectedPreviousHoldingQuantity,
    String? expectedWalletVersion,
    required DateTime executedAt,
    required String sellReason,
    String? sourceStopLossOrderId,
  });
}

abstract interface class ExecuteBuyClock {
  DateTime now();
}

abstract interface class ExecuteBuyIdGenerator {
  String nextTradeId();
  String nextHoldingId({
    required String userId,
    required String symbol,
  });
}

class SystemExecuteBuyClock implements ExecuteBuyClock {
  const SystemExecuteBuyClock();

  @override
  DateTime now() => DateTime.now();
}

class PersistedVirtualWallet {
  final String userId;
  final VirtualWallet wallet;
  final String? version;
  final DateTime? updatedAt;

  const PersistedVirtualWallet({
    required this.userId,
    required this.wallet,
    this.version,
    this.updatedAt,
  });
}

sealed class BuyTransactionCommitResult {
  const BuyTransactionCommitResult();
}

class BuyTransactionCommitSuccess extends BuyTransactionCommitResult {
  final String? confirmationId;
  final DateTime committedAt;

  const BuyTransactionCommitSuccess({
    this.confirmationId,
    required this.committedAt,
  });
}

class BuyTransactionCommitFailure extends BuyTransactionCommitResult {
  final BuyTransactionFailure failure;

  const BuyTransactionCommitFailure(this.failure);
}

enum BuyTransactionFailureCode {
  persistenceFailure,
  concurrencyConflict,
}

class BuyTransactionFailure {
  final BuyTransactionFailureCode code;
  final String message;

  const BuyTransactionFailure({
    required this.code,
    required this.message,
  });
}

sealed class SellTransactionCommitResult {
  const SellTransactionCommitResult();
}

class SellTransactionCommitSuccess extends SellTransactionCommitResult {
  final String? confirmationId;
  final DateTime committedAt;

  const SellTransactionCommitSuccess({
    this.confirmationId,
    required this.committedAt,
  });
}

class SellTransactionCommitFailure extends SellTransactionCommitResult {
  final SellTransactionFailure failure;

  const SellTransactionCommitFailure(this.failure);
}

enum SellTransactionFailureCode {
  persistenceFailure,
  concurrencyConflict,
}

class SellTransactionFailure {
  final SellTransactionFailureCode code;
  final String message;

  const SellTransactionFailure({
    required this.code,
    required this.message,
  });
}

class MarketTickerUnavailableException implements Exception {
  final String symbol;
  final String message;

  const MarketTickerUnavailableException({
    required this.symbol,
    this.message = 'Fresh ticker is unavailable.',
  });

  @override
  String toString() => 'MarketTickerUnavailableException($symbol): $message';
}
