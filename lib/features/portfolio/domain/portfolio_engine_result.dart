import 'package:flutter/foundation.dart';

import '../../../features/trading/domain/trading_failure.dart';

sealed class PortfolioEngineResult {
  const PortfolioEngineResult();

  bool get isSuccess => this is PortfolioEngineSuccess;
  bool get isFailure => this is PortfolioEngineRejected;
}

@immutable
class PortfolioEngineSuccess extends PortfolioEngineResult {
  final PortfolioSnapshot snapshot;

  const PortfolioEngineSuccess({
    required this.snapshot,
  });
}

@immutable
class PortfolioEngineRejected extends PortfolioEngineResult {
  final TradingFailure failure;

  const PortfolioEngineRejected(this.failure);
}

@immutable
class PortfolioSnapshot {
  final WalletSummary wallet;
  final PortfolioTotals totals;
  final List<AssetSummary> assetSummaries;
  final AllocationSummary allocation;
  final PortfolioPerformance performance;
  final DateTime evaluatedAt;

  const PortfolioSnapshot({
    required this.wallet,
    required this.totals,
    required this.assetSummaries,
    required this.allocation,
    required this.performance,
    required this.evaluatedAt,
  });
}

@immutable
class WalletSummary {
  final double cashBalanceInr;
  final double lockedBalanceInr;
  final double availableBalanceInr;
  final double initialBalanceInr;

  const WalletSummary({
    required this.cashBalanceInr,
    required this.lockedBalanceInr,
    required this.availableBalanceInr,
    required this.initialBalanceInr,
  });
}

@immutable
class PortfolioTotals {
  final double cashBalanceInr;
  final double cryptoValueInr;
  final double portfolioValueInr;
  final double investedAmountInr;
  final double totalCostBasisInr;
  final double totalUnrealizedProfitLossInr;
  final double totalRealizedProfitLossInr;
  final double overallProfitLossInr;
  final double overallReturnPercent;
  final double cashAllocationPercent;
  final double cryptoAllocationPercent;
  final int numberOfAssets;
  final int numberOfOpenHoldings;
  final DateTime evaluatedAt;

  const PortfolioTotals({
    required this.cashBalanceInr,
    required this.cryptoValueInr,
    required this.portfolioValueInr,
    required this.investedAmountInr,
    required this.totalCostBasisInr,
    required this.totalUnrealizedProfitLossInr,
    required this.totalRealizedProfitLossInr,
    required this.overallProfitLossInr,
    required this.overallReturnPercent,
    required this.cashAllocationPercent,
    required this.cryptoAllocationPercent,
    required this.numberOfAssets,
    required this.numberOfOpenHoldings,
    required this.evaluatedAt,
  });
}

@immutable
class AssetSummary {
  final String assetSymbol;
  final double quantity;
  final double averageEntryPriceInr;
  final double currentPriceInr;
  final double currentValueInr;
  final double costBasisInr;
  final double unrealizedProfitLossInr;
  final double returnPercent;
  final double allocationPercent;
  final double assetWeight;
  final DateTime lastUpdated;

  const AssetSummary({
    required this.assetSymbol,
    required this.quantity,
    required this.averageEntryPriceInr,
    required this.currentPriceInr,
    required this.currentValueInr,
    required this.costBasisInr,
    required this.unrealizedProfitLossInr,
    required this.returnPercent,
    required this.allocationPercent,
    required this.assetWeight,
    required this.lastUpdated,
  });
}

@immutable
class AllocationSummary {
  final double cashPercent;
  final double cryptoPercent;
  final List<AssetAllocation> assets;

  const AllocationSummary({
    required this.cashPercent,
    required this.cryptoPercent,
    required this.assets,
  });
}

@immutable
class AssetAllocation {
  final String assetSymbol;
  final double valueInr;
  final double allocationPercent;
  final double weight;

  const AssetAllocation({
    required this.assetSymbol,
    required this.valueInr,
    required this.allocationPercent,
    required this.weight,
  });
}

@immutable
class PortfolioPerformance {
  final AssetSummary? bestPerformingAsset;
  final AssetSummary? worstPerformingAsset;
  final AssetSummary? largestPosition;
  final AssetSummary? smallestPosition;
  final AssetSummary? highestAllocation;
  final AssetSummary? lowestAllocation;

  const PortfolioPerformance({
    required this.bestPerformingAsset,
    required this.worstPerformingAsset,
    required this.largestPosition,
    required this.smallestPosition,
    required this.highestAllocation,
    required this.lowestAllocation,
  });
}
