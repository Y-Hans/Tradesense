import 'package:cryptoedu/features/trading/application/trading_event_publisher.dart';
import 'package:cryptoedu/features/trading/application/trading_events.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryTradingEventPublisher', () {
    final occurredAt = DateTime.utc(2026, 8, 1, 10);

    test('registers a single listener and delivers event payloads', () {
      final publisher = InMemoryTradingEventPublisher();
      final delivered = <TradingEvent>[];

      publisher.subscribe(delivered.add);
      publisher.publish(
        FirstTradeCompleted(
          userId: 'user_1',
          occurredAt: occurredAt,
          tradeId: 'trade_1',
          assetSymbol: 'BTC',
          side: TradeSide.buy,
          totalAmountInr: 1000.0,
        ),
      );

      expect(delivered, hasLength(1));
      expect(delivered.single, isA<FirstTradeCompleted>());
      expect(delivered.single.userId, 'user_1');
      expect(delivered.single.occurredAt, occurredAt);
      expect(delivered.single.payload, {
        'tradeId': 'trade_1',
        'assetSymbol': 'BTC',
        'side': 'buy',
        'totalAmountInr': 1000.0,
      });
    });

    test('removes listeners through subscription cancellation', () {
      final publisher = InMemoryTradingEventPublisher();
      var deliveryCount = 0;
      final subscription = publisher.subscribe((event) => deliveryCount += 1);

      subscription.cancel();
      publisher.publish(_portfolioViewed(occurredAt));

      expect(deliveryCount, 0);
    });

    test('delivers to multiple listeners in registration order', () {
      final publisher = InMemoryTradingEventPublisher();
      final callOrder = <String>[];

      publisher
        ..subscribe((event) => callOrder.add('first:${event.eventName}'))
        ..subscribe((event) => callOrder.add('second:${event.eventName}'));

      publisher.publish(_portfolioViewed(occurredAt));

      expect(callOrder, ['first:PortfolioViewed', 'second:PortfolioViewed']);
    });

    test('does not deliver twice when the same listener is registered twice',
        () {
      final publisher = InMemoryTradingEventPublisher();
      var deliveryCount = 0;
      void listener(TradingEvent event) => deliveryCount += 1;

      publisher
        ..subscribe(listener)
        ..subscribe(listener);
      publisher.publish(_portfolioViewed(occurredAt));

      expect(deliveryCount, 1);
    });

    test('survives listener exceptions and continues delivery', () {
      final publisher = InMemoryTradingEventPublisher();
      final delivered = <TradingEvent>[];

      publisher
        ..subscribe((event) => throw StateError('listener failed'))
        ..subscribe(delivered.add);

      publisher.publish(_portfolioViewed(occurredAt));

      expect(delivered, hasLength(1));
      expect(delivered.single, isA<PortfolioViewed>());
    });

    test('keeps repeated execution deterministic', () {
      final publisher = InMemoryTradingEventPublisher();
      final eventNames = <String>[];
      publisher.subscribe((event) => eventNames.add(event.eventName));

      publisher
        ..publish(_portfolioViewed(occurredAt))
        ..publish(
          TradeHistoryViewed(
            userId: 'user_1',
            occurredAt: occurredAt,
            totalTrades: 2,
            profitableTrades: 1,
            losingTrades: 0,
          ),
        );

      expect(eventNames, ['PortfolioViewed', 'TradeHistoryViewed']);
    });
  });
}

PortfolioViewed _portfolioViewed(DateTime occurredAt) {
  return PortfolioViewed(
    userId: 'user_1',
    occurredAt: occurredAt,
    portfolioValueInr: 1000.0,
    numberOfAssets: 1,
    numberOfOpenHoldings: 1,
  );
}
