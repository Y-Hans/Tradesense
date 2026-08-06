import 'dart:async';
import '../../../features/trading/application/execute_buy_contracts.dart';
import '../../../features/trading/application/execute_sell_contracts.dart';
import '../../../shared/models/holding.dart';
import '../../../shared/models/trade.dart';
import '../../../shared/models/virtual_wallet.dart';
import 'mock_repositories.dart';

class TradingTransactionAdapter
    implements
        ExecuteBuyWalletRepository,
        ExecuteBuyHoldingRepository,
        TradingTransactionRepository {
  final MockTradingRepository repo;

  TradingTransactionAdapter(this.repo);

  @override
  Future<PersistedVirtualWallet?> getWalletForUser(String userId) async {
    return PersistedVirtualWallet(
      userId: userId,
      wallet: repo.wallet,
      version: '1',
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Holding?> getHoldingForUserAsset({
    required String userId,
    required String symbol,
  }) async {
    try {
      return repo.holdings.firstWhere((h) => h.symbol == symbol);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<BuyTransactionCommitResult> commitBuy({
    required String userId,
    required VirtualWallet updatedWallet,
    required Holding updatedHolding,
    required Trade trade,
    required double expectedPreviousWalletBalanceInr,
    String? expectedWalletVersion,
    required DateTime executedAt,
  }) async {
    repo.updateWallet(updatedWallet);
    repo.updateHolding(updatedHolding);
    repo.addTrade(trade);
    return BuyTransactionCommitSuccess(committedAt: executedAt);
  }

  @override
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
  }) async {
    repo.updateWallet(updatedWallet);
    if (updatedHolding.quantity <= 0.000001) {
      repo.removeHolding(updatedHolding.symbol);
    } else {
      repo.updateHolding(updatedHolding);
    }
    repo.addTrade(trade);
    return SellTransactionCommitSuccess(committedAt: executedAt);
  }
}
