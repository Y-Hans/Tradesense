import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/core/events/domain_event_providers.dart';

void main() {
  group('InMemoryDomainEventPublisher Unit Tests', () {
    late InMemoryDomainEventPublisher publisher;

    setUp(() {
      publisher = InMemoryDomainEventPublisher();
    });

    tearDown(() {
      publisher.dispose();
    });

    test('publishes events to subscribers preserving order', () async {
      final receivedEvents = <DomainEvent>[];
      final subscription = publisher.events.listen(receivedEvents.add);

      final event1 = RiskEvaluationCompleted(
        riskScore: 45,
        riskLevel: 'moderate',
        reasonCodes: const ['Elevated market volatility'],
        proposedTradeSizeInr: 5000.0,
        hasStopLoss: true,
      );

      final event2 = DisciplineEvaluationCompleted(
        disciplineScore: 85,
        reasonCodes: const ['Disciplined position sizing'],
        positionSizePercentage: 12.5,
        usedStopLoss: true,
      );

      final event3 = TradeExecuted(
        tradeId: 'tr_123',
        userId: 'user_1',
        symbol: 'BTC',
        side: 'buy',
        quantity: 0.1,
        executionPriceInr: 50000.0,
        totalAmountInr: 5000.0,
        hasStopLoss: true,
        stopLossPriceInr: 47500.0,
      );

      publisher.publish(event1);
      publisher.publish(event2);
      publisher.publish(event3);

      expect(receivedEvents.length, equals(3));
      expect(receivedEvents[0], equals(event1));
      expect(receivedEvents[1], equals(event2));
      expect(receivedEvents[2], equals(event3));

      expect(receivedEvents[0].eventType, equals('RiskEvaluationCompleted'));
      expect(
          receivedEvents[1].eventType, equals('DisciplineEvaluationCompleted'));
      expect(receivedEvents[2].eventType, equals('TradeExecuted'));

      await subscription.cancel();
    });

    test('supports multiple independent subscribers', () async {
      final sub1Events = <DomainEvent>[];
      final sub2Events = <DomainEvent>[];

      final sub1 = publisher.events.listen(sub1Events.add);
      final sub2 = publisher.events.listen(sub2Events.add);

      final event = CoachSessionCompleted(
        tradeId: 'tr_999',
        userId: 'user_42',
        riskScore: 30,
        disciplineScore: 90,
        isFallback: false,
        providerName: 'OpenRouterAIProvider',
      );

      publisher.publish(event);

      expect(sub1Events.length, equals(1));
      expect(sub2Events.length, equals(1));
      expect(sub1Events.first, equals(event));
      expect(sub2Events.first, equals(event));

      await sub1.cancel();
      await sub2.cancel();
    });

    test('does not throw when publishing after disposal', () {
      publisher.dispose();
      expect(
        () => publisher.publish(
          RiskEvaluationCompleted(
            riskScore: 10,
            riskLevel: 'low',
            reasonCodes: const [],
            proposedTradeSizeInr: 100.0,
            hasStopLoss: true,
          ),
        ),
        returnsNormally,
      );
    });

    test('timestamp is automatically populated when omitted', () {
      final before = DateTime.now();
      final event = RiskEvaluationCompleted(
        riskScore: 20,
        riskLevel: 'low',
        reasonCodes: const [],
        proposedTradeSizeInr: 200.0,
        hasStopLoss: false,
      );
      final after = DateTime.now();

      expect(
        event.occurredAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        event.occurredAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });
}
