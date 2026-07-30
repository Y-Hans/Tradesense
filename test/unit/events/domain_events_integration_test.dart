import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryptoedu/core/providers/app_providers.dart';
import 'package:cryptoedu/features/coach/domain/coach_context_builder.dart';
import 'package:cryptoedu/features/coach/domain/coach_orchestrator.dart';
import 'package:cryptoedu/features/intelligence/domain/reason_code.dart';
import 'package:cryptoedu/shared/models/risk_score.dart';
import 'package:cryptoedu/shared/models/discipline_score.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:cryptoedu/shared/models/portfolio.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:cryptoedu/core/contracts/provider_contracts.dart';
import 'package:cryptoedu/shared/models/coach_request.dart';

class MockTestAIProvider implements AIProvider {
  @override
  Future<CoachResponse> generateCoachFeedback(CoachRequest request) async {
    return const CoachResponse(
      whatDoneWell: 'Good position sizing.',
      whatIncreasedRisk: 'High market volatility.',
      whatToLearn: 'Risk management principle.',
      whatToConsiderNext: 'Use stop loss.',
      aiProvider: 'MockTestAIProvider',
      modelId: 'mock-test-model',
      promptVersion: '1.0.0',
      latencyMs: 120,
    );
  }
}

void main() {
  group('Domain Event System Integration Tests', () {
    late ProviderContainer container;
    late InMemoryDomainEventPublisher publisher;
    late List<DomainEvent> publishedEvents;

    setUp(() {
      publisher = InMemoryDomainEventPublisher();
      publishedEvents = [];
      publisher.events.listen(publishedEvents.add);

      container = ProviderContainer(
        overrides: [
          domainEventPublisherProvider.overrideWithValue(publisher),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      publisher.dispose();
    });

    test('Trade execution publishes TradeExecuted event', () async {
      final tradingRepo = container.read(tradingRepositoryProvider);
      final trade = await tradingRepo.executeMarketBuy(
        symbol: 'BTC',
        quantity: 0.1,
        executionPriceInr: 50000.0,
        stopLossPriceInr: 47500.0,
      );

      expect(publishedEvents.length, equals(1));
      final event = publishedEvents.first as TradeExecuted;
      expect(event.tradeId, equals(trade.id));
      expect(event.symbol, equals('BTC'));
      expect(event.side, equals('buy'));
      expect(event.quantity, equals(0.1));
      expect(event.hasStopLoss, isTrue);
      expect(event.stopLossPriceInr, equals(47500.0));
    });

    test('Risk evaluation publishes RiskEvaluationCompleted event', () {
      final intelRepo = container.read(intelligenceRepositoryProvider);
      final portfolio = Portfolio(
        wallet: VirtualWallet.initial(),
        holdings: const [],
        totalRealisedPnlInr: 0.0,
      );

      final score = intelRepo.calculateRiskScore(
        portfolio: portfolio,
        proposedTradeSizeInr: 10000.0,
        hasStopLoss: true,
        assetVolatility: 2.0,
      );

      expect(publishedEvents.length, equals(1));
      final event = publishedEvents.first as RiskEvaluationCompleted;
      expect(event.riskScore, equals(score.score));
      expect(event.hasStopLoss, isTrue);
      expect(event.proposedTradeSizeInr, equals(10000.0));
    });

    test('Discipline evaluation publishes DisciplineEvaluationCompleted event', () {
      final intelRepo = container.read(intelligenceRepositoryProvider);
      const riskScore = RiskScore(
        score: 30,
        level: RiskLevel.low,
        concentrationScore: 10.0,
        sizingScore: 10.0,
        volatilityScore: 10.0,
        stopLossScore: 0.0,
        explanations: [],
      );

      final score = intelRepo.calculateDisciplineScore(
        currentRiskScore: riskScore,
        positionSizePercentage: 10.0,
        usedStopLoss: true,
        portfolioConcentration: 20.0,
        tradeFrequency24h: 1,
      );

      expect(publishedEvents.length, equals(1));
      final event = publishedEvents.first as DisciplineEvaluationCompleted;
      expect(event.disciplineScore, equals(score.score));
      expect(event.usedStopLoss, isTrue);
      expect(event.positionSizePercentage, equals(10.0));
    });

    test('CoachOrchestrator session publishes CoachSessionCompleted event', () async {
      final mockAi = MockTestAIProvider();
      final orchestrator = CoachOrchestrator(
        aiProvider: mockAi,
        aiEnabled: true,
        eventPublisher: publisher,
      );

      const sampleRisk = RiskScore(
        score: 25,
        level: RiskLevel.low,
        concentrationScore: 10.0,
        sizingScore: 10.0,
        volatilityScore: 5.0,
        stopLossScore: 0.0,
        explanations: [],
      );
      const sampleDiscipline = DisciplineScore(
        score: 90,
        riskMgmtScore: 100.0,
        positionSizingScore: 100.0,
        stopLossDisciplineScore: 100.0,
        concentrationScore: 100.0,
        frequencyScore: 100.0,
        breakdownNotes: [],
      );

      final coachContext = CoachContextBuilder.build(
        symbol: 'ETH',
        side: TradeSide.buy,
        quantity: 1.0,
        executionPriceInr: 200000.0,
        totalTradeValueInr: 200000.0,
        hasStopLoss: true,
        tradeId: 'trade_456',
        totalEquityInr: 1000000.0,
        virtualCashBalanceInr: 800000.0,
        riskScore: sampleRisk,
        disciplineScore: sampleDiscipline,
        riskReasonCodes: const [RiskReasonCode.stopLossPresent],
        disciplineReasonCodes: const [DisciplineReasonCode.usedStopLoss],
      );

      await orchestrator.getCoachResponse(coachContext, userId: 'user_test');

      expect(publishedEvents.length, equals(1));
      final event = publishedEvents.first as CoachSessionCompleted;
      expect(event.tradeId, equals('trade_456'));
      expect(event.userId, equals('user_test'));
      expect(event.riskScore, equals(25));
      expect(event.disciplineScore, equals(90));
      expect(event.isFallback, isFalse);
      expect(event.providerName, equals('MockTestAIProvider'));
    });
  });
}
