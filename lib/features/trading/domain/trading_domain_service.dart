import 'package:decimal/decimal.dart';

import '../../../core/utils/financial_math.dart';
import '../../../shared/models/crypto_asset.dart';
import '../../../shared/models/holding.dart';
import '../../../shared/models/market_ticker.dart';
import '../../../shared/models/trade.dart';
import '../../../shared/models/virtual_wallet.dart';
import 'buy_trade_result.dart';
import 'trading_failure.dart';

class TradingDomainService {
  static const Duration defaultTickerFreshness = Duration(seconds: 30);
  static const int cryptoQuantityScale = 18;

  final Duration tickerFreshness;
  final double? minimumBuyAmountInr;

  const TradingDomainService({
    this.tickerFreshness = defaultTickerFreshness,
    this.minimumBuyAmountInr,
  });

  BuyTradeResult calculateBuy({
    required VirtualWallet wallet,
    required CryptoAsset asset,
    required MarketTicker ticker,
    required double buyAmountInr,
    required Holding? existingHolding,
    required DateTime executedAt,
    required DateTime evaluatedAt,
    required String tradeId,
    required String userId,
    required String holdingId,
    required int disciplineScoreAtTrade,
    required int riskScoreAtTrade,
  }) {
    final assetSymbol = _normalizeSymbol(asset.symbol);
    final assetFailure = _validateAsset(asset, assetSymbol);
    if (assetFailure != null) return BuyTradeRejected(assetFailure);

    final metadataFailure = _validateTradeMetadata(
      tradeId: tradeId,
      userId: userId,
      holdingId: existingHolding == null ? holdingId : existingHolding.id,
    );
    if (metadataFailure != null) return BuyTradeRejected(metadataFailure);

    final amountFailure = _validateBuyAmount(buyAmountInr);
    if (amountFailure != null) return BuyTradeRejected(amountFailure);

    final walletFailure = _validateWallet(wallet);
    if (walletFailure != null) return BuyTradeRejected(walletFailure);

    final tickerFailure = _validateTicker(
      ticker: ticker,
      assetSymbol: assetSymbol,
      evaluatedAt: evaluatedAt,
    );
    if (tickerFailure != null) return BuyTradeRejected(tickerFailure);

    final holdingFailure = _validateExistingHolding(
      existingHolding,
      assetSymbol,
    );
    if (holdingFailure != null) return BuyTradeRejected(holdingFailure);

    final buyAmountPaise = FinancialMath.inrToPaise(buyAmountInr);
    final availablePaise = FinancialMath.inrToPaise(wallet.availableBalanceInr);
    if (availablePaise < buyAmountPaise) {
      return const BuyTradeRejected(
        TradingFailure(
          code: TradingFailureCode.insufficientFunds,
          message: 'Wallet has insufficient available INR cash.',
        ),
      );
    }

    final balancePaise = FinancialMath.inrToPaise(wallet.balanceInr);
    final newBalancePaise = balancePaise - buyAmountPaise;
    final amountSpent = _inrFromPaise(buyAmountPaise);
    final executionPrice = _decimalFromDouble(ticker.priceInr);
    final purchasedQuantity = _divide(
      amountSpent,
      executionPrice,
      scale: cryptoQuantityScale,
    );

    final previousQuantity = existingHolding == null
        ? Decimal.zero
        : _decimalFromDouble(existingHolding.quantity);
    final previousAverageEntry = existingHolding == null
        ? Decimal.zero
        : _decimalFromDouble(existingHolding.averageEntryPriceInr);
    final previousCostBasis = previousQuantity * previousAverageEntry;
    final newQuantity = previousQuantity + purchasedQuantity;
    final newCostBasis = previousCostBasis + amountSpent;
    final newAverageEntry = _divide(
      newCostBasis,
      newQuantity,
      scale: cryptoQuantityScale,
    );

    final updatedWallet = wallet.copyWith(
      balanceInr: FinancialMath.paiseToInr(newBalancePaise),
    );
    final updatedHolding = (existingHolding == null)
        ? Holding(
            id: holdingId,
            userId: userId,
            symbol: assetSymbol,
            quantity: newQuantity.toDouble(),
            averageEntryPriceInr: newAverageEntry.toDouble(),
            currentPriceInr: ticker.priceInr,
          )
        : existingHolding.copyWith(
            quantity: newQuantity.toDouble(),
            averageEntryPriceInr: newAverageEntry.toDouble(),
            currentPriceInr: ticker.priceInr,
          );
    final trade = Trade(
      id: tradeId,
      userId: userId,
      symbol: assetSymbol,
      side: TradeSide.buy,
      type: OrderType.market,
      quantity: purchasedQuantity.toDouble(),
      executionPriceInr: ticker.priceInr,
      totalAmountInr: amountSpent.toDouble(),
      timestamp: executedAt,
      disciplineScoreAtTrade: disciplineScoreAtTrade,
      riskScoreAtTrade: riskScoreAtTrade,
    );

    return BuyTradeSuccess(
      updatedWallet: updatedWallet,
      updatedHolding: updatedHolding,
      trade: trade,
      amountSpentInr: amountSpent.toDouble(),
      purchasedQuantity: purchasedQuantity.toDouble(),
      executionPriceInr: executionPrice.toDouble(),
      previousWalletBalanceInr: wallet.balanceInr,
      newWalletBalanceInr: updatedWallet.balanceInr,
      previousHoldingQuantity: previousQuantity.toDouble(),
      newHoldingQuantity: newQuantity.toDouble(),
      previousCostBasisInr: previousCostBasis.toDouble(),
      newCostBasisInr: newCostBasis.toDouble(),
      previousAverageEntryPriceInr: previousAverageEntry.toDouble(),
      newAverageEntryPriceInr: newAverageEntry.toDouble(),
    );
  }

  TradingFailure? _validateAsset(CryptoAsset asset, String assetSymbol) {
    if (assetSymbol.isEmpty) {
      return const TradingFailure(
        code: TradingFailureCode.invalidAsset,
        message: 'Asset symbol must not be blank.',
      );
    }
    if (asset.name.trim().isEmpty || !asset.currentPriceInr.isFinite) {
      return const TradingFailure(
        code: TradingFailureCode.invalidAsset,
        message: 'Asset data required for a trade is invalid.',
      );
    }
    if (!asset.isSupportedV1 ||
        !CryptoAsset.supportedV1Symbols.contains(assetSymbol)) {
      return const TradingFailure(
        code: TradingFailureCode.unsupportedAsset,
        message: 'Asset is not supported for V1 trading.',
      );
    }
    return null;
  }

  TradingFailure? _validateTradeMetadata({
    required String tradeId,
    required String userId,
    required String holdingId,
  }) {
    if (tradeId.trim().isEmpty ||
        userId.trim().isEmpty ||
        holdingId.trim().isEmpty) {
      return const TradingFailure(
        code: TradingFailureCode.invalidTradeMetadata,
        message: 'Trade, user, and holding identifiers must be supplied.',
      );
    }
    return null;
  }

  TradingFailure? _validateBuyAmount(double buyAmountInr) {
    if (!buyAmountInr.isFinite || buyAmountInr <= 0) {
      return const TradingFailure(
        code: TradingFailureCode.invalidBuyAmount,
        message: 'Buy amount must be a positive finite INR amount.',
      );
    }
    final minimum = minimumBuyAmountInr;
    if (minimum != null && buyAmountInr < minimum) {
      return const TradingFailure(
        code: TradingFailureCode.invalidBuyAmount,
        message: 'Buy amount is below the configured minimum trade amount.',
      );
    }
    return null;
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

  TradingFailure? _validateTicker({
    required MarketTicker ticker,
    required String assetSymbol,
    required DateTime evaluatedAt,
  }) {
    final tickerSymbol = _normalizeSymbol(ticker.symbol);
    if (tickerSymbol.isEmpty ||
        !ticker.priceInr.isFinite ||
        !ticker.high24h.isFinite ||
        !ticker.low24h.isFinite ||
        !ticker.volume24h.isFinite ||
        ticker.priceInr <= 0 ||
        ticker.high24h <= 0 ||
        ticker.low24h <= 0 ||
        ticker.volume24h < 0) {
      return const TradingFailure(
        code: TradingFailureCode.invalidMarketPrice,
        message: 'Ticker data required for market execution is invalid.',
      );
    }
    if (tickerSymbol != assetSymbol) {
      return const TradingFailure(
        code: TradingFailureCode.mismatchedTicker,
        message: 'Ticker symbol does not match the selected asset.',
      );
    }
    if (evaluatedAt.difference(ticker.timestamp) > tickerFreshness) {
      return const TradingFailure(
        code: TradingFailureCode.staleTicker,
        message: 'Ticker price is stale for deterministic execution.',
      );
    }
    return null;
  }

  TradingFailure? _validateExistingHolding(
    Holding? holding,
    String assetSymbol,
  ) {
    if (holding == null) return null;

    if (_normalizeSymbol(holding.symbol) != assetSymbol) {
      return const TradingFailure(
        code: TradingFailureCode.mismatchedHolding,
        message: 'Existing holding symbol does not match the selected asset.',
      );
    }
    if (!holding.quantity.isFinite ||
        !holding.averageEntryPriceInr.isFinite ||
        !holding.currentPriceInr.isFinite ||
        holding.quantity < 0 ||
        holding.averageEntryPriceInr < 0 ||
        holding.currentPriceInr < 0 ||
        (holding.quantity > 0 && holding.averageEntryPriceInr == 0)) {
      return const TradingFailure(
        code: TradingFailureCode.invalidExistingHolding,
        message: 'Existing holding financial state is invalid.',
      );
    }
    return null;
  }

  String _normalizeSymbol(String symbol) => symbol.trim().toUpperCase();

  Decimal _decimalFromDouble(double value) => Decimal.parse(value.toString());

  Decimal _inrFromPaise(int paise) {
    return _divide(
      Decimal.fromInt(paise),
      Decimal.fromInt(100),
      scale: 2,
    );
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
}
