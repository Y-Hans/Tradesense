import 'package:decimal/decimal.dart';

import '../../../core/utils/financial_math.dart';
import '../../../features/trading/domain/trading_failure.dart';
import '../../../shared/models/holding.dart';
import '../../../shared/models/market_ticker.dart';
import '../../../shared/models/trade.dart';
import '../../../shared/models/virtual_wallet.dart';
import 'portfolio_engine_result.dart';

class PortfolioEngine {
  static const Duration defaultTickerFreshness = Duration(seconds: 30);
  static const int cryptoQuantityScale = 18;
  static const int percentScale = 4;

  final Duration tickerFreshness;

  const PortfolioEngine({
    this.tickerFreshness = defaultTickerFreshness,
  });

  PortfolioEngineResult calculate({
    required VirtualWallet wallet,
    required List<Holding> holdings,
    required List<MarketTicker> tickers,
    List<Trade> trades = const [],
    required DateTime evaluatedAt,
  }) {
    final walletFailure = _validateWallet(wallet);
    if (walletFailure != null) return PortfolioEngineRejected(walletFailure);

    final holdingFailure = _validateHoldings(holdings);
    if (holdingFailure != null) {
      return PortfolioEngineRejected(holdingFailure);
    }

    final tickerIndexResult = _buildTickerIndex(tickers, evaluatedAt);
    if (tickerIndexResult.failure != null) {
      return PortfolioEngineRejected(tickerIndexResult.failure!);
    }
    final tickerBySymbol = tickerIndexResult.tickersBySymbol;

    final tradesFailure = _validateTrades(trades);
    if (tradesFailure != null) return PortfolioEngineRejected(tradesFailure);

    final realizedResult = _calculateRealizedProfitLoss(trades);
    if (realizedResult.failure != null) {
      return PortfolioEngineRejected(realizedResult.failure!);
    }

    final cashBalance = _decimalFromDouble(wallet.balanceInr);
    final assetWorkItems = <_AssetWorkItem>[];
    var cryptoValue = Decimal.zero;
    var totalCostBasis = Decimal.zero;
    var totalUnrealized = Decimal.zero;

    for (final holding in holdings) {
      final assetSymbol = _normalizeSymbol(holding.symbol);
      final ticker = tickerBySymbol[assetSymbol];
      if (ticker == null) {
        return const PortfolioEngineRejected(
          TradingFailure(
            code: TradingFailureCode.invalidMarketPrice,
            message: 'Every holding requires a matching market ticker.',
          ),
        );
      }

      final quantity = _decimalFromDouble(holding.quantity);
      final averageEntry = _decimalFromDouble(holding.averageEntryPriceInr);
      final currentPrice = _decimalFromDouble(ticker.priceInr);
      final costBasis = quantity * averageEntry;
      final currentValue = quantity * currentPrice;
      final unrealized = currentValue - costBasis;

      cryptoValue += currentValue;
      totalCostBasis += costBasis;
      totalUnrealized += unrealized;
      assetWorkItems.add(
        _AssetWorkItem(
          symbol: assetSymbol,
          quantity: quantity,
          averageEntryPrice: averageEntry,
          currentPrice: currentPrice,
          currentValue: currentValue,
          costBasis: costBasis,
          unrealizedProfitLoss: unrealized,
          lastUpdated: ticker.timestamp,
        ),
      );
    }

    final portfolioValue = cashBalance + cryptoValue;
    final totalRealized = realizedResult.realizedProfitLoss;
    final overallProfitLoss = totalUnrealized + totalRealized;
    final assetSummaries = List<AssetSummary>.unmodifiable(
      assetWorkItems.map(
        (item) {
          final allocation = _percentage(item.currentValue, portfolioValue);
          return AssetSummary(
            assetSymbol: item.symbol,
            quantity: item.quantity.toDouble(),
            averageEntryPriceInr: _inrDouble(item.averageEntryPrice),
            currentPriceInr: _inrDouble(item.currentPrice),
            currentValueInr: _inrDouble(item.currentValue),
            costBasisInr: _inrDouble(item.costBasis),
            unrealizedProfitLossInr: _inrDouble(item.unrealizedProfitLoss),
            returnPercent: _percentage(
              item.unrealizedProfitLoss,
              item.costBasis,
            ),
            allocationPercent: allocation,
            assetWeight: allocation,
            lastUpdated: item.lastUpdated,
          );
        },
      ),
    );

    final openAssetSummaries = assetSummaries
        .where((summary) => summary.quantity > 0)
        .toList(growable: false);
    final cashAllocation = _percentage(cashBalance, portfolioValue);
    final cryptoAllocation = _percentage(cryptoValue, portfolioValue);

    final snapshot = PortfolioSnapshot(
      wallet: WalletSummary(
        cashBalanceInr: _inrDouble(cashBalance),
        lockedBalanceInr: _inrDouble(_decimalFromDouble(wallet.lockedInr)),
        availableBalanceInr:
            _inrDouble(_decimalFromDouble(wallet.availableBalanceInr)),
        initialBalanceInr:
            _inrDouble(_decimalFromDouble(wallet.initialBalanceInr)),
      ),
      totals: PortfolioTotals(
        cashBalanceInr: _inrDouble(cashBalance),
        cryptoValueInr: _inrDouble(cryptoValue),
        portfolioValueInr: _inrDouble(portfolioValue),
        investedAmountInr: _inrDouble(totalCostBasis),
        totalCostBasisInr: _inrDouble(totalCostBasis),
        totalUnrealizedProfitLossInr: _inrDouble(totalUnrealized),
        totalRealizedProfitLossInr: _inrDouble(totalRealized),
        overallProfitLossInr: _inrDouble(overallProfitLoss),
        overallReturnPercent: _percentage(overallProfitLoss, totalCostBasis),
        cashAllocationPercent: cashAllocation,
        cryptoAllocationPercent: cryptoAllocation,
        numberOfAssets: assetSummaries.length,
        numberOfOpenHoldings: openAssetSummaries.length,
        evaluatedAt: evaluatedAt,
      ),
      assetSummaries: assetSummaries,
      allocation: AllocationSummary(
        cashPercent: cashAllocation,
        cryptoPercent: cryptoAllocation,
        assets: List<AssetAllocation>.unmodifiable(
          assetSummaries.map(
            (summary) => AssetAllocation(
              assetSymbol: summary.assetSymbol,
              valueInr: summary.currentValueInr,
              allocationPercent: summary.allocationPercent,
              weight: summary.assetWeight,
            ),
          ),
        ),
      ),
      performance: PortfolioPerformance(
        bestPerformingAsset: _maxBy(
          openAssetSummaries,
          (summary) => summary.returnPercent,
        ),
        worstPerformingAsset: _minBy(
          openAssetSummaries,
          (summary) => summary.returnPercent,
        ),
        largestPosition: _maxBy(
          openAssetSummaries,
          (summary) => summary.currentValueInr,
        ),
        smallestPosition: _minBy(
          openAssetSummaries,
          (summary) => summary.currentValueInr,
        ),
        highestAllocation: _maxBy(
          openAssetSummaries,
          (summary) => summary.allocationPercent,
        ),
        lowestAllocation: _minBy(
          openAssetSummaries,
          (summary) => summary.allocationPercent,
        ),
      ),
      evaluatedAt: evaluatedAt,
    );

    return PortfolioEngineSuccess(snapshot: snapshot);
  }

  TradingFailure? _validateWallet(VirtualWallet wallet) {
    if (!wallet.balanceInr.isFinite ||
        !wallet.lockedInr.isFinite ||
        !wallet.initialBalanceInr.isFinite ||
        !wallet.availableBalanceInr.isFinite ||
        wallet.balanceInr < 0 ||
        wallet.lockedInr < 0 ||
        wallet.initialBalanceInr < 0 ||
        wallet.availableBalanceInr < 0) {
      return const TradingFailure(
        code: TradingFailureCode.invalidWallet,
        message: 'Wallet cash state is invalid.',
      );
    }
    return null;
  }

  TradingFailure? _validateHoldings(List<Holding> holdings) {
    final seenSymbols = <String>{};
    for (final holding in holdings) {
      final symbol = _normalizeSymbol(holding.symbol);
      if (symbol.isEmpty ||
          holding.id.trim().isEmpty ||
          holding.userId.trim().isEmpty ||
          !holding.quantity.isFinite ||
          !holding.averageEntryPriceInr.isFinite ||
          !holding.currentPriceInr.isFinite ||
          holding.quantity < 0 ||
          holding.averageEntryPriceInr < 0 ||
          holding.currentPriceInr < 0 ||
          (holding.quantity > 0 && holding.averageEntryPriceInr == 0) ||
          !seenSymbols.add(symbol)) {
        return const TradingFailure(
          code: TradingFailureCode.invalidExistingHolding,
          message: 'Holding financial state is invalid.',
        );
      }
    }
    return null;
  }

  _TickerIndexResult _buildTickerIndex(
    List<MarketTicker> tickers,
    DateTime evaluatedAt,
  ) {
    final tickerBySymbol = <String, MarketTicker>{};
    for (final ticker in tickers) {
      final symbol = _normalizeSymbol(ticker.symbol);
      if (symbol.isEmpty ||
          !ticker.priceInr.isFinite ||
          !ticker.high24h.isFinite ||
          !ticker.low24h.isFinite ||
          !ticker.volume24h.isFinite ||
          ticker.priceInr <= 0 ||
          ticker.high24h <= 0 ||
          ticker.low24h <= 0 ||
          ticker.volume24h < 0) {
        return const _TickerIndexResult.failure(
          TradingFailure(
            code: TradingFailureCode.invalidMarketPrice,
            message: 'Ticker data required for portfolio valuation is invalid.',
          ),
        );
      }
      if (tickerBySymbol.containsKey(symbol)) {
        return const _TickerIndexResult.failure(
          TradingFailure(
            code: TradingFailureCode.invalidMarketPrice,
            message: 'Duplicate market tickers are invalid.',
          ),
        );
      }
      if (evaluatedAt.difference(ticker.timestamp) > tickerFreshness) {
        return const _TickerIndexResult.failure(
          TradingFailure(
            code: TradingFailureCode.staleTicker,
            message: 'Ticker price is stale for deterministic valuation.',
          ),
        );
      }
      tickerBySymbol[symbol] = ticker;
    }
    return _TickerIndexResult.success(Map.unmodifiable(tickerBySymbol));
  }

  TradingFailure? _validateTrades(List<Trade> trades) {
    for (final trade in trades) {
      if (trade.id.trim().isEmpty ||
          trade.userId.trim().isEmpty ||
          _normalizeSymbol(trade.symbol).isEmpty ||
          !trade.quantity.isFinite ||
          !trade.executionPriceInr.isFinite ||
          !trade.totalAmountInr.isFinite ||
          trade.quantity <= 0 ||
          trade.executionPriceInr <= 0 ||
          trade.totalAmountInr < 0 ||
          trade.disciplineScoreAtTrade < 0 ||
          trade.riskScoreAtTrade < 0) {
        return const TradingFailure(
          code: TradingFailureCode.invalidTradeMetadata,
          message: 'Trade history contains invalid financial state.',
        );
      }
    }
    return null;
  }

  _RealizedProfitLossResult _calculateRealizedProfitLoss(List<Trade> trades) {
    final positions = <String, _TradePosition>{};
    var realizedProfitLoss = Decimal.zero;
    final orderedTrades = List<Trade>.of(trades)
      ..sort((left, right) => left.timestamp.compareTo(right.timestamp));

    for (final trade in orderedTrades) {
      final symbol = _normalizeSymbol(trade.symbol);
      final position = positions.putIfAbsent(symbol, _TradePosition.new);
      final quantity = _decimalFromDouble(trade.quantity);
      final totalAmount = _decimalFromDouble(trade.totalAmountInr);

      if (trade.side == TradeSide.buy) {
        position.costBasis += totalAmount;
        position.quantity += quantity;
        continue;
      }

      if (quantity > position.quantity) {
        return _RealizedProfitLossResult.failure(
          const TradingFailure(
            code: TradingFailureCode.insufficientHoldings,
            message:
                'Trade history sells more quantity than it previously buys.',
          ),
        );
      }

      final removedCostBasis = position.quantity == Decimal.zero
          ? Decimal.zero
          : _divide(
              position.costBasis * quantity,
              position.quantity,
              scale: cryptoQuantityScale,
            );
      realizedProfitLoss += totalAmount - removedCostBasis;
      position.quantity -= quantity;
      position.costBasis = position.quantity == Decimal.zero
          ? Decimal.zero
          : position.costBasis - removedCostBasis;
    }

    return _RealizedProfitLossResult.success(realizedProfitLoss);
  }

  String _normalizeSymbol(String symbol) => symbol.trim().toUpperCase();

  Decimal _decimalFromDouble(double value) => Decimal.parse(value.toString());

  double _inrDouble(Decimal value) {
    return FinancialMath.paiseToInr(FinancialMath.inrToPaise(value.toDouble()));
  }

  double _percentage(Decimal numerator, Decimal denominator) {
    if (denominator == Decimal.zero) return 0.0;
    final value = _divide(
      numerator * Decimal.fromInt(100),
      denominator,
      scale: percentScale,
    );
    return value.toDouble();
  }

  Decimal _divide(
    Decimal numerator,
    Decimal denominator, {
    required int scale,
  }) {
    return (numerator / denominator).toDecimal(
      scaleOnInfinitePrecision: scale,
    );
  }

  AssetSummary? _maxBy(
    List<AssetSummary> summaries,
    double Function(AssetSummary summary) valueOf,
  ) {
    if (summaries.isEmpty) return null;
    return summaries.reduce(
      (best, current) => valueOf(current) > valueOf(best) ? current : best,
    );
  }

  AssetSummary? _minBy(
    List<AssetSummary> summaries,
    double Function(AssetSummary summary) valueOf,
  ) {
    if (summaries.isEmpty) return null;
    return summaries.reduce(
      (best, current) => valueOf(current) < valueOf(best) ? current : best,
    );
  }
}

class _TickerIndexResult {
  final Map<String, MarketTicker> tickersBySymbol;
  final TradingFailure? failure;

  const _TickerIndexResult.success(this.tickersBySymbol) : failure = null;
  const _TickerIndexResult.failure(this.failure) : tickersBySymbol = const {};
}

class _RealizedProfitLossResult {
  final Decimal realizedProfitLoss;
  final TradingFailure? failure;

  _RealizedProfitLossResult.success(this.realizedProfitLoss) : failure = null;
  _RealizedProfitLossResult.failure(this.failure)
      : realizedProfitLoss = Decimal.zero;
}

class _AssetWorkItem {
  final String symbol;
  final Decimal quantity;
  final Decimal averageEntryPrice;
  final Decimal currentPrice;
  final Decimal currentValue;
  final Decimal costBasis;
  final Decimal unrealizedProfitLoss;
  final DateTime lastUpdated;

  const _AssetWorkItem({
    required this.symbol,
    required this.quantity,
    required this.averageEntryPrice,
    required this.currentPrice,
    required this.currentValue,
    required this.costBasis,
    required this.unrealizedProfitLoss,
    required this.lastUpdated,
  });
}

class _TradePosition {
  Decimal quantity = Decimal.zero;
  Decimal costBasis = Decimal.zero;
}
