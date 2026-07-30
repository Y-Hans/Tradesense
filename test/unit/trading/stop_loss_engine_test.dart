import 'package:cryptoedu/features/trading/domain/stop_loss_engine.dart';
import 'package:cryptoedu/features/trading/domain/stop_loss_evaluation_result.dart';
import 'package:cryptoedu/features/trading/domain/trading_failure.dart';
import 'package:cryptoedu/shared/models/holding.dart';
import 'package:cryptoedu/shared/models/market_ticker.dart';
import 'package:cryptoedu/shared/models/stop_loss_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StopLossEngine.evaluate', () {
    const engine = StopLossEngine();
    final evaluatedAt = DateTime.utc(2026, 7, 30, 10);

    StopLossEvaluationResult evaluate({
      List<StopLossOrder>? orders,
      List<Holding>? holdings,
      List<MarketTicker>? tickers,
      DateTime? timestamp,
    }) {
      return engine.evaluate(
        orders: orders ?? [_order()],
        holdings: holdings ?? [_holding()],
        tickers: tickers ?? [_ticker(timestamp: evaluatedAt)],
        evaluatedAt: timestamp ?? evaluatedAt,
      );
    }

    TradingFailureCode rejectedCode(StopLossEvaluationResult result) {
      expect(result.rejectedOrders, hasLength(1));
      return result.rejectedOrders.single.failure.code;
    }

    test('empty orders returns an empty immutable evaluation result', () {
      final result = evaluate(orders: []);

      expect(result.triggeredOrders, isEmpty);
      expect(result.pendingOrders, isEmpty);
      expect(result.expiredOrders, isEmpty);
      expect(result.rejectedOrders, isEmpty);
      expect(result.sellRequests, isEmpty);
      expect(result.evaluatedAt, evaluatedAt);
      expect(() => result.sellRequests.add(_sellRequest()),
          throwsUnsupportedError);
    });

    test('single pending order stays pending above trigger price', () {
      final result = evaluate(
        orders: [_order(triggerPriceInr: 90000.0)],
        tickers: [_ticker(priceInr: 91000.0, timestamp: evaluatedAt)],
      );

      expect(result.pendingOrders, hasLength(1));
      expect(result.pendingOrders.single.id, 'sl_1');
      expect(result.triggeredOrders, isEmpty);
      expect(result.sellRequests, isEmpty);
    });

    test('single triggered order generates a sell execution request', () {
      final result = evaluate(
        orders: [_order(quantity: 0.3, triggerPriceInr: 95000.0)],
        holdings: [_holding(quantity: 2.0)],
        tickers: [_ticker(priceInr: 94000.0, timestamp: evaluatedAt)],
      );

      expect(result.triggeredOrders, hasLength(1));
      expect(result.triggeredOrders.single.status, StopLossStatus.triggered);
      expect(result.triggeredOrders.single.triggeredAt, evaluatedAt);
      expect(result.pendingOrders, isEmpty);
      expect(result.sellRequests, hasLength(1));
      final request = result.sellRequests.single;
      expect(request.orderId, 'sl_1');
      expect(request.assetSymbol, 'BTC');
      expect(request.quantity, 0.3);
      expect(request.marketPriceInr, 94000.0);
      expect(request.triggerPriceInr, 95000.0);
      expect(request.estimatedProceedsInr, 28200.0);
      expect(request.evaluatedAt, evaluatedAt);
      expect(request.reason, SellExecutionRequest.stopLossReason);
    });

    test('multiple assets evaluate independently', () {
      final result = evaluate(
        orders: [
          _order(id: 'sl_eth', symbol: 'ETH', triggerPriceInr: 2000.0),
          _order(id: 'sl_btc', symbol: 'BTC', triggerPriceInr: 95000.0),
        ],
        holdings: [
          _holding(symbol: 'BTC', quantity: 2.0),
          _holding(id: 'holding_eth', symbol: 'ETH', quantity: 5.0),
        ],
        tickers: [
          _ticker(symbol: 'ETH', priceInr: 2100.0, timestamp: evaluatedAt),
          _ticker(symbol: 'BTC', priceInr: 94000.0, timestamp: evaluatedAt),
        ],
      );

      expect(result.triggeredOrders.map((order) => order.id), ['sl_btc']);
      expect(result.pendingOrders.map((order) => order.id), ['sl_eth']);
      expect(
          result.sellRequests.map((request) => request.assetSymbol), ['BTC']);
    });

    test('multiple orders for the same asset trigger independently', () {
      final result = evaluate(
        orders: [
          _order(id: 'sl_95', quantity: 2.0, triggerPriceInr: 95000.0),
          _order(id: 'sl_90', quantity: 3.0, triggerPriceInr: 90000.0),
          _order(id: 'sl_85', quantity: 5.0, triggerPriceInr: 85000.0),
        ],
        holdings: [_holding(quantity: 10.0)],
        tickers: [_ticker(priceInr: 87500.0, timestamp: evaluatedAt)],
      );

      expect(
          result.triggeredOrders.map((order) => order.id), ['sl_90', 'sl_95']);
      expect(result.pendingOrders.map((order) => order.id), ['sl_85']);
      expect(
          result.sellRequests.map((request) => request.quantity), [3.0, 2.0]);
    });

    test('partial stop-loss protects only the requested quantity', () {
      final holding = _holding(quantity: 10.0);

      final result = evaluate(
        orders: [_order(quantity: 3.0, triggerPriceInr: 95000.0)],
        holdings: [holding],
        tickers: [_ticker(priceInr: 90000.0, timestamp: evaluatedAt)],
      );

      expect(result.sellRequests.single.quantity, 3.0);
      expect(holding.quantity, 10.0);
    });

    test('exact trigger price and price below stop both trigger', () {
      final exact = evaluate(
        orders: [_order(triggerPriceInr: 95000.0)],
        tickers: [_ticker(priceInr: 95000.0, timestamp: evaluatedAt)],
      );
      final below = evaluate(
        orders: [_order(triggerPriceInr: 95000.0)],
        tickers: [_ticker(priceInr: 94999.99, timestamp: evaluatedAt)],
      );

      expect(exact.triggeredOrders, hasLength(1));
      expect(below.triggeredOrders, hasLength(1));
    });

    test('duplicate active order IDs are rejected deterministically', () {
      final result = evaluate(
        orders: [
          _order(id: 'sl_dup', symbol: 'ETH'),
          _order(id: 'sl_dup', symbol: 'BTC'),
        ],
        holdings: [
          _holding(symbol: 'BTC'),
          _holding(id: 'holding_eth', symbol: 'ETH'),
        ],
        tickers: [
          _ticker(symbol: 'BTC', timestamp: evaluatedAt),
          _ticker(symbol: 'ETH', timestamp: evaluatedAt),
        ],
      );

      expect(result.rejectedOrders, hasLength(2));
      expect(result.rejectedOrders.map((item) => item.order.symbol),
          ['BTC', 'ETH']);
      expect(
        result.rejectedOrders.map((item) => item.failure.code).toSet(),
        {TradingFailureCode.invalidTradeMetadata},
      );
    });

    test('missing ticker is rejected', () {
      final result = evaluate(tickers: []);

      expect(rejectedCode(result), TradingFailureCode.invalidMarketPrice);
    });

    test('missing holding is rejected', () {
      final result = evaluate(holdings: []);

      expect(rejectedCode(result), TradingFailureCode.missingHolding);
    });

    test('oversized quantity is rejected', () {
      final result = evaluate(
        orders: [_order(quantity: 2.1)],
        holdings: [_holding(quantity: 2.0)],
      );

      expect(rejectedCode(result), TradingFailureCode.insufficientHoldings);
    });

    test('expired order is ignored without generating a sell request', () {
      final result = evaluate(
        orders: [
          _order(
            triggerPriceInr: 95000.0,
            expiresAt: evaluatedAt.subtract(const Duration(seconds: 1)),
          ),
        ],
        tickers: [_ticker(priceInr: 90000.0, timestamp: evaluatedAt)],
      );

      expect(result.expiredOrders, hasLength(1));
      expect(result.triggeredOrders, isEmpty);
      expect(result.sellRequests, isEmpty);
      expect(result.rejectedOrders, isEmpty);
    });

    test(
        'future creation timestamp is rejected when evaluation time is supplied',
        () {
      final result = evaluate(
        orders: [
          _order(createdAt: evaluatedAt.add(const Duration(seconds: 1))),
        ],
      );

      expect(rejectedCode(result), TradingFailureCode.invalidTradeMetadata);
    });

    test('invalid prices are rejected', () {
      expect(
        rejectedCode(evaluate(orders: [_order(triggerPriceInr: -1.0)])),
        TradingFailureCode.invalidMarketPrice,
      );
      expect(
        rejectedCode(evaluate(orders: [_order(triggerPriceInr: double.nan)])),
        TradingFailureCode.invalidMarketPrice,
      );
      expect(
        rejectedCode(
          evaluate(tickers: [_ticker(priceInr: -1.0, timestamp: evaluatedAt)]),
        ),
        TradingFailureCode.invalidMarketPrice,
      );
    });

    test('invalid quantities are rejected', () {
      expect(
        rejectedCode(evaluate(orders: [_order(quantity: 0.0)])),
        TradingFailureCode.invalidSellQuantity,
      );
      expect(
        rejectedCode(evaluate(orders: [_order(quantity: -0.1)])),
        TradingFailureCode.invalidSellQuantity,
      );
      expect(
        rejectedCode(evaluate(orders: [_order(quantity: double.infinity)])),
        TradingFailureCode.invalidSellQuantity,
      );
    });

    test('invalid symbols are rejected', () {
      final result = evaluate(orders: [_order(symbol: '   ')]);

      expect(rejectedCode(result), TradingFailureCode.invalidAsset);
    });

    test('deterministic ordering ignores input ordering', () {
      final result = evaluate(
        orders: [
          _order(id: 'sol_2', symbol: 'SOL', triggerPriceInr: 10.0),
          _order(id: 'btc_2', symbol: 'BTC', triggerPriceInr: 95000.0),
          _order(id: 'btc_1', symbol: 'BTC', triggerPriceInr: 95000.0),
          _order(id: 'eth_1', symbol: 'ETH', triggerPriceInr: 2000.0),
        ],
        holdings: [
          _holding(id: 'holding_sol', symbol: 'SOL', quantity: 4.0),
          _holding(id: 'holding_eth', symbol: 'ETH', quantity: 4.0),
          _holding(symbol: 'BTC', quantity: 4.0),
        ],
        tickers: [
          _ticker(symbol: 'SOL', priceInr: 11.0, timestamp: evaluatedAt),
          _ticker(symbol: 'ETH', priceInr: 1500.0, timestamp: evaluatedAt),
          _ticker(symbol: 'BTC', priceInr: 90000.0, timestamp: evaluatedAt),
        ],
      );

      expect(result.triggeredOrders.map((order) => order.id), [
        'btc_1',
        'btc_2',
        'eth_1',
      ]);
      expect(result.pendingOrders.map((order) => order.id), ['sol_2']);
      expect(result.sellRequests.map((request) => request.orderId), [
        'btc_1',
        'btc_2',
        'eth_1',
      ]);
    });

    test('inputs are not mutated and output lists are immutable', () {
      final order = _order(symbol: ' btc ', triggerPriceInr: 95000.0);
      final holding = _holding(quantity: 2.0);
      final ticker = _ticker(priceInr: 90000.0, timestamp: evaluatedAt);
      final orderBefore = order.toJson();
      final holdingBefore = holding.toJson();
      final tickerBefore = ticker.toJson();

      final result = evaluate(
        orders: [order],
        holdings: [holding],
        tickers: [ticker],
      );

      expect(order.toJson(), orderBefore);
      expect(holding.toJson(), holdingBefore);
      expect(ticker.toJson(), tickerBefore);
      expect(result.triggeredOrders.single.symbol, 'BTC');
      expect(() => result.triggeredOrders.add(result.triggeredOrders.single),
          throwsUnsupportedError);
      expect(() => result.sellRequests.add(result.sellRequests.single),
          throwsUnsupportedError);
    });

    test('same valid input produces equivalent results', () {
      final orders = [_order(quantity: 0.3, triggerPriceInr: 95000.0)];
      final holdings = [_holding(quantity: 2.0)];
      final tickers = [_ticker(priceInr: 90000.0, timestamp: evaluatedAt)];

      final first = engine.evaluate(
        orders: orders,
        holdings: holdings,
        tickers: tickers,
        evaluatedAt: evaluatedAt,
      );
      final second = engine.evaluate(
        orders: orders,
        holdings: holdings,
        tickers: tickers,
        evaluatedAt: evaluatedAt,
      );

      expect(second.triggeredOrders.single.toJson(),
          first.triggeredOrders.single.toJson());
      expect(second.sellRequests.single.orderId,
          first.sellRequests.single.orderId);
      expect(second.sellRequests.single.estimatedProceedsInr,
          first.sellRequests.single.estimatedProceedsInr);
      expect(second.evaluatedAt, first.evaluatedAt);
    });

    test(
        'optional evaluation timestamp resolves deterministically from tickers',
        () {
      final result = engine.evaluate(
        orders: [
          _order(createdAt: evaluatedAt.subtract(const Duration(days: 1)))
        ],
        holdings: [_holding()],
        tickers: [_ticker(priceInr: 90000.0, timestamp: evaluatedAt)],
      );

      expect(result.evaluatedAt, evaluatedAt);
      expect(result.triggeredOrders, hasLength(1));
    });

    test('stale ticker is rejected using evaluation timestamp', () {
      final result = evaluate(
        tickers: [
          _ticker(
            timestamp: evaluatedAt.subtract(const Duration(seconds: 31)),
          ),
        ],
      );

      expect(rejectedCode(result), TradingFailureCode.staleTicker);
    });
  });
}

StopLossOrder _order({
  String id = 'sl_1',
  String tradeId = 'trade_buy_1',
  String userId = 'user_1',
  String symbol = 'BTC',
  double triggerPriceInr = 95000.0,
  double quantity = 1.0,
  StopLossStatus status = StopLossStatus.active,
  DateTime? createdAt,
  DateTime? expiresAt,
  DateTime? triggeredAt,
}) {
  return StopLossOrder(
    id: id,
    tradeId: tradeId,
    userId: userId,
    symbol: symbol,
    triggerPriceInr: triggerPriceInr,
    quantity: quantity,
    status: status,
    createdAt: createdAt ?? DateTime.utc(2026, 7, 30, 9),
    expiresAt: expiresAt,
    triggeredAt: triggeredAt,
  );
}

Holding _holding({
  String id = 'holding_btc',
  String userId = 'user_1',
  String symbol = 'BTC',
  double quantity = 2.0,
  double averageEntryPriceInr = 100000.0,
  double currentPriceInr = 100000.0,
}) {
  return Holding(
    id: id,
    userId: userId,
    symbol: symbol,
    quantity: quantity,
    averageEntryPriceInr: averageEntryPriceInr,
    currentPriceInr: currentPriceInr,
  );
}

MarketTicker _ticker({
  String symbol = 'BTC',
  double priceInr = 90000.0,
  required DateTime timestamp,
}) {
  final positivePrice = priceInr.isFinite && priceInr > 0 ? priceInr : 1.0;
  return MarketTicker(
    symbol: symbol,
    priceInr: priceInr,
    high24h: positivePrice * 1.1,
    low24h: positivePrice * 0.9,
    volume24h: 1000000.0,
    timestamp: timestamp,
  );
}

SellExecutionRequest _sellRequest() {
  return SellExecutionRequest(
    orderId: 'sl_1',
    assetSymbol: 'BTC',
    quantity: 1.0,
    marketPriceInr: 90000.0,
    triggerPriceInr: 95000.0,
    estimatedProceedsInr: 90000.0,
    evaluatedAt: DateTime.utc(2026, 7, 30, 10),
  );
}
