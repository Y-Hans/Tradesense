import 'package:decimal/decimal.dart';

import '../../../core/utils/financial_math.dart';
import '../../../shared/models/holding.dart';
import '../../../shared/models/market_ticker.dart';
import '../../../shared/models/stop_loss_order.dart';
import 'stop_loss_evaluation_result.dart';
import 'trading_failure.dart';

class StopLossEngine {
  static const Duration defaultTickerFreshness = Duration(seconds: 30);
  static const int cryptoQuantityScale = 18;

  final Duration tickerFreshness;

  const StopLossEngine({
    this.tickerFreshness = defaultTickerFreshness,
  });

  StopLossEvaluationResult evaluate({
    required List<StopLossOrder> orders,
    required List<Holding> holdings,
    required List<MarketTicker> tickers,
    DateTime? evaluatedAt,
  }) {
    final resolvedEvaluatedAt = evaluatedAt ??
        _resolveEvaluationTime(
          orders: orders,
          tickers: tickers,
        );
    final holdingIndex = _buildHoldingIndex(holdings);
    final tickerIndex = _buildTickerIndex(tickers, resolvedEvaluatedAt);
    final duplicateActiveOrderIds = _duplicateActiveOrderIds(orders);
    final triggeredOrders = <StopLossOrder>[];
    final pendingOrders = <StopLossOrder>[];
    final expiredOrders = <StopLossOrder>[];
    final rejectedOrders = <StopLossRejectedOrder>[];
    final sellRequests = <SellExecutionRequest>[];

    final activeOrders = orders
        .where((order) => order.status == StopLossStatus.active)
        .toList(growable: false)
      ..sort(_compareOrders);

    for (final order in activeOrders) {
      final normalizedOrder = _normalizedOrder(order);
      final validationFailure = _validateOrder(
        normalizedOrder,
        duplicateActiveOrderIds: duplicateActiveOrderIds,
        evaluatedAt: evaluatedAt,
      );
      if (validationFailure != null) {
        rejectedOrders.add(
          StopLossRejectedOrder(
            order: normalizedOrder,
            failure: validationFailure,
          ),
        );
        continue;
      }

      if (_isExpired(normalizedOrder, resolvedEvaluatedAt)) {
        expiredOrders.add(normalizedOrder);
        continue;
      }

      final symbol = _normalizeSymbol(normalizedOrder.symbol);
      final holdingFailure = holdingIndex.failuresBySymbol[symbol];
      if (holdingFailure != null) {
        rejectedOrders.add(
          StopLossRejectedOrder(
              order: normalizedOrder, failure: holdingFailure),
        );
        continue;
      }

      final holding = holdingIndex.itemsBySymbol[symbol];
      if (holding == null) {
        rejectedOrders.add(
          StopLossRejectedOrder(
            order: normalizedOrder,
            failure: const TradingFailure(
              code: TradingFailureCode.missingHolding,
              message: 'A matching holding is required for stop-loss orders.',
            ),
          ),
        );
        continue;
      }

      final tickerFailure = tickerIndex.failuresBySymbol[symbol];
      if (tickerFailure != null) {
        rejectedOrders.add(
          StopLossRejectedOrder(order: normalizedOrder, failure: tickerFailure),
        );
        continue;
      }

      final ticker = tickerIndex.itemsBySymbol[symbol];
      if (ticker == null) {
        rejectedOrders.add(
          StopLossRejectedOrder(
            order: normalizedOrder,
            failure: const TradingFailure(
              code: TradingFailureCode.invalidMarketPrice,
              message: 'A matching market ticker is required for stop-loss.',
            ),
          ),
        );
        continue;
      }

      final quantity = _decimalFromDouble(normalizedOrder.quantity);
      final holdingQuantity = _decimalFromDouble(holding.quantity);
      if (quantity > holdingQuantity) {
        rejectedOrders.add(
          StopLossRejectedOrder(
            order: normalizedOrder,
            failure: const TradingFailure(
              code: TradingFailureCode.insufficientHoldings,
              message: 'Stop-loss quantity exceeds the owned asset quantity.',
            ),
          ),
        );
        continue;
      }

      final currentPrice = _decimalFromDouble(ticker.priceInr);
      final triggerPrice = _decimalFromDouble(normalizedOrder.triggerPriceInr);
      if (currentPrice <= triggerPrice) {
        final triggeredOrder = normalizedOrder.copyWith(
          status: StopLossStatus.triggered,
          triggeredAt: resolvedEvaluatedAt,
        );
        triggeredOrders.add(triggeredOrder);
        sellRequests.add(
          SellExecutionRequest(
            orderId: normalizedOrder.id,
            assetSymbol: symbol,
            quantity: quantity.toDouble(),
            marketPriceInr: _inrDouble(currentPrice),
            triggerPriceInr: _inrDouble(triggerPrice),
            estimatedProceedsInr: _inrDouble(quantity * currentPrice),
            evaluatedAt: resolvedEvaluatedAt,
          ),
        );
      } else {
        pendingOrders.add(normalizedOrder);
      }
    }

    triggeredOrders.sort(_compareOrders);
    pendingOrders.sort(_compareOrders);
    expiredOrders.sort(_compareOrders);
    rejectedOrders.sort(_compareRejectedOrders);
    sellRequests.sort(_compareSellRequests);

    return StopLossEvaluationResult(
      triggeredOrders: List<StopLossOrder>.unmodifiable(triggeredOrders),
      pendingOrders: List<StopLossOrder>.unmodifiable(pendingOrders),
      expiredOrders: List<StopLossOrder>.unmodifiable(expiredOrders),
      rejectedOrders: List<StopLossRejectedOrder>.unmodifiable(rejectedOrders),
      sellRequests: List<SellExecutionRequest>.unmodifiable(sellRequests),
      evaluatedAt: resolvedEvaluatedAt,
    );
  }

  TradingFailure? _validateOrder(
    StopLossOrder order, {
    required Set<String> duplicateActiveOrderIds,
    required DateTime? evaluatedAt,
  }) {
    final orderId = order.id.trim();
    if (orderId.isEmpty ||
        order.tradeId.trim().isEmpty ||
        order.userId.trim().isEmpty) {
      return const TradingFailure(
        code: TradingFailureCode.invalidTradeMetadata,
        message: 'Stop-loss order identifiers must be supplied.',
      );
    }
    if (duplicateActiveOrderIds.contains(orderId)) {
      return const TradingFailure(
        code: TradingFailureCode.invalidTradeMetadata,
        message: 'Duplicate active stop-loss order identifiers are invalid.',
      );
    }
    if (_normalizeSymbol(order.symbol).isEmpty) {
      return const TradingFailure(
        code: TradingFailureCode.invalidAsset,
        message: 'Stop-loss asset symbol must not be blank.',
      );
    }
    if (!order.triggerPriceInr.isFinite || order.triggerPriceInr < 0) {
      return const TradingFailure(
        code: TradingFailureCode.invalidMarketPrice,
        message: 'Stop-loss trigger price must be a finite non-negative INR.',
      );
    }
    if (!order.quantity.isFinite || order.quantity <= 0) {
      return const TradingFailure(
        code: TradingFailureCode.invalidSellQuantity,
        message: 'Stop-loss quantity must be a positive finite quantity.',
      );
    }
    if (evaluatedAt != null && order.createdAt.isAfter(evaluatedAt)) {
      return const TradingFailure(
        code: TradingFailureCode.invalidTradeMetadata,
        message: 'Stop-loss order cannot be created after evaluation time.',
      );
    }
    return null;
  }

  bool _isExpired(StopLossOrder order, DateTime evaluatedAt) {
    final expiresAt = order.expiresAt;
    return expiresAt != null && !expiresAt.isAfter(evaluatedAt);
  }

  _Index<Holding> _buildHoldingIndex(List<Holding> holdings) {
    final itemsBySymbol = <String, Holding>{};
    final failuresBySymbol = <String, TradingFailure>{};
    for (final holding in holdings) {
      final symbol = _normalizeSymbol(holding.symbol);
      if (symbol.isEmpty) continue;

      if (!_isValidHolding(holding)) {
        failuresBySymbol[symbol] = const TradingFailure(
          code: TradingFailureCode.invalidExistingHolding,
          message: 'Matching holding financial state is invalid.',
        );
        itemsBySymbol.remove(symbol);
        continue;
      }

      if (itemsBySymbol.containsKey(symbol) ||
          failuresBySymbol.containsKey(symbol)) {
        failuresBySymbol[symbol] = const TradingFailure(
          code: TradingFailureCode.invalidExistingHolding,
          message: 'Duplicate holdings for an asset are invalid.',
        );
        itemsBySymbol.remove(symbol);
        continue;
      }

      itemsBySymbol[symbol] = holding.copyWith(symbol: symbol);
    }
    return _Index(
      itemsBySymbol: Map<String, Holding>.unmodifiable(itemsBySymbol),
      failuresBySymbol:
          Map<String, TradingFailure>.unmodifiable(failuresBySymbol),
    );
  }

  bool _isValidHolding(Holding holding) {
    return holding.id.trim().isNotEmpty &&
        holding.userId.trim().isNotEmpty &&
        _normalizeSymbol(holding.symbol).isNotEmpty &&
        holding.quantity.isFinite &&
        holding.averageEntryPriceInr.isFinite &&
        holding.currentPriceInr.isFinite &&
        holding.quantity >= 0 &&
        holding.averageEntryPriceInr >= 0 &&
        holding.currentPriceInr >= 0 &&
        (holding.quantity == 0 || holding.averageEntryPriceInr > 0);
  }

  _Index<MarketTicker> _buildTickerIndex(
    List<MarketTicker> tickers,
    DateTime evaluatedAt,
  ) {
    final itemsBySymbol = <String, MarketTicker>{};
    final failuresBySymbol = <String, TradingFailure>{};
    for (final ticker in tickers) {
      final symbol = _normalizeSymbol(ticker.symbol);
      if (symbol.isEmpty) continue;

      final failure = _validateTicker(ticker, evaluatedAt);
      if (failure != null) {
        failuresBySymbol[symbol] = failure;
        itemsBySymbol.remove(symbol);
        continue;
      }

      if (itemsBySymbol.containsKey(symbol) ||
          failuresBySymbol.containsKey(symbol)) {
        failuresBySymbol[symbol] = const TradingFailure(
          code: TradingFailureCode.invalidMarketPrice,
          message: 'Duplicate market tickers are invalid.',
        );
        itemsBySymbol.remove(symbol);
        continue;
      }

      itemsBySymbol[symbol] = MarketTicker(
        symbol: symbol,
        priceInr: ticker.priceInr,
        high24h: ticker.high24h,
        low24h: ticker.low24h,
        volume24h: ticker.volume24h,
        timestamp: ticker.timestamp,
      );
    }
    return _Index(
      itemsBySymbol: Map<String, MarketTicker>.unmodifiable(itemsBySymbol),
      failuresBySymbol:
          Map<String, TradingFailure>.unmodifiable(failuresBySymbol),
    );
  }

  TradingFailure? _validateTicker(MarketTicker ticker, DateTime evaluatedAt) {
    if (!ticker.priceInr.isFinite ||
        !ticker.high24h.isFinite ||
        !ticker.low24h.isFinite ||
        !ticker.volume24h.isFinite ||
        ticker.priceInr <= 0 ||
        ticker.high24h <= 0 ||
        ticker.low24h <= 0 ||
        ticker.volume24h < 0) {
      return const TradingFailure(
        code: TradingFailureCode.invalidMarketPrice,
        message: 'Ticker data required for stop-loss evaluation is invalid.',
      );
    }
    if (evaluatedAt.difference(ticker.timestamp) > tickerFreshness) {
      return const TradingFailure(
        code: TradingFailureCode.staleTicker,
        message: 'Ticker price is stale for deterministic stop-loss.',
      );
    }
    return null;
  }

  Set<String> _duplicateActiveOrderIds(List<StopLossOrder> orders) {
    final seen = <String>{};
    final duplicates = <String>{};
    for (final order in orders) {
      if (order.status != StopLossStatus.active) continue;
      final orderId = order.id.trim();
      if (orderId.isEmpty) continue;
      if (!seen.add(orderId)) duplicates.add(orderId);
    }
    return duplicates;
  }

  StopLossOrder _normalizedOrder(StopLossOrder order) {
    return order.copyWith(
      id: order.id.trim(),
      tradeId: order.tradeId.trim(),
      userId: order.userId.trim(),
      symbol: _normalizeSymbol(order.symbol),
    );
  }

  DateTime _resolveEvaluationTime({
    required List<StopLossOrder> orders,
    required List<MarketTicker> tickers,
  }) {
    final timestamps = <DateTime>[
      ...tickers.map((ticker) => ticker.timestamp),
      ...orders.map((order) => order.createdAt),
    ];
    if (timestamps.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return timestamps
        .reduce((latest, value) => value.isAfter(latest) ? value : latest);
  }

  int _compareOrders(StopLossOrder left, StopLossOrder right) {
    final symbolCompare = _normalizeSymbol(left.symbol).compareTo(
      _normalizeSymbol(right.symbol),
    );
    if (symbolCompare != 0) return symbolCompare;
    return left.id.trim().compareTo(right.id.trim());
  }

  int _compareRejectedOrders(
    StopLossRejectedOrder left,
    StopLossRejectedOrder right,
  ) {
    return _compareOrders(left.order, right.order);
  }

  int _compareSellRequests(
    SellExecutionRequest left,
    SellExecutionRequest right,
  ) {
    final symbolCompare = left.assetSymbol.compareTo(right.assetSymbol);
    if (symbolCompare != 0) return symbolCompare;
    return left.orderId.compareTo(right.orderId);
  }

  String _normalizeSymbol(String symbol) => symbol.trim().toUpperCase();

  Decimal _decimalFromDouble(double value) => Decimal.parse(value.toString());

  double _inrDouble(Decimal value) {
    return FinancialMath.paiseToInr(FinancialMath.inrToPaise(value.toDouble()));
  }
}

class _Index<T> {
  final Map<String, T> itemsBySymbol;
  final Map<String, TradingFailure> failuresBySymbol;

  const _Index({
    required this.itemsBySymbol,
    required this.failuresBySymbol,
  });
}
