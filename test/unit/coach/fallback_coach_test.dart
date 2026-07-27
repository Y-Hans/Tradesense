import 'package:cryptoedu/features/coach/domain/coach_context_builder.dart';
import 'package:cryptoedu/features/coach/domain/fallback_coach.dart';
import 'package:cryptoedu/features/intelligence/domain/reason_code.dart';
import 'package:cryptoedu/shared/models/discipline_score.dart';
import 'package:cryptoedu/shared/models/risk_score.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FallbackCoach Engine Unit Tests', () {
    const lowRiskScore = RiskScore(
      score: 20,
      level: RiskLevel.low,
      concentrationScore: 10.0,
      sizingScore: 10.0,
      volatilityScore: 15.0,
      stopLossScore: 0.0,
      explanations: ['Low risk'],
    );

    const highRiskScore = RiskScore(
      score: 75,
      level: RiskLevel.high,
      concentrationScore: 80.0,
      sizingScore: 70.0,
      volatilityScore: 60.0,
      stopLossScore: 100.0,
      explanations: ['High risk'],
    );

    const extremeRiskScore = RiskScore(
      score: 90,
      level: RiskLevel.extreme,
      concentrationScore: 90.0,
      sizingScore: 90.0,
      volatilityScore: 80.0,
      stopLossScore: 100.0,
      explanations: ['Extreme risk'],
    );

    const moderateRiskScore = RiskScore(
      score: 45,
      level: RiskLevel.moderate,
      concentrationScore: 40.0,
      sizingScore: 40.0,
      volatilityScore: 30.0,
      stopLossScore: 0.0,
      explanations: ['Moderate risk'],
    );

    const highDisciplineScore = DisciplineScore(
      score: 95,
      riskMgmtScore: 100.0,
      positionSizingScore: 100.0,
      stopLossDisciplineScore: 100.0,
      concentrationScore: 100.0,
      frequencyScore: 100.0,
      breakdownNotes: ['Disciplined'],
    );

    const lowDisciplineScore = DisciplineScore(
      score: 30,
      riskMgmtScore: 0.0,
      positionSizingScore: 20.0,
      stopLossDisciplineScore: 0.0,
      concentrationScore: 40.0,
      frequencyScore: 0.0,
      breakdownNotes: ['Poor discipline'],
    );

    test(
        'Positive behavior emits encouraging educational feedback in whatDoneWell',
        () {
      final context = CoachContextBuilder.build(
        symbol: 'BTC',
        side: TradeSide.buy,
        quantity: 0.01,
        executionPriceInr: 5000000.0,
        totalTradeValueInr: 50000.0,
        hasStopLoss: true,
        stopLossPriceInr: 4800000.0,
        totalEquityInr: 1000000.0,
        virtualCashBalanceInr: 950000.0,
        riskScore: lowRiskScore,
        disciplineScore: highDisciplineScore,
        riskReasonCodes: const [
          RiskReasonCode.balancedConcentration,
          RiskReasonCode.controlledPositionSize,
          RiskReasonCode.normalVolatility,
          RiskReasonCode.stopLossPresent,
        ],
        disciplineReasonCodes: const [
          DisciplineReasonCode.goodRiskManagement,
          DisciplineReasonCode.disciplinedPositionSize,
          DisciplineReasonCode.usedStopLoss,
          DisciplineReasonCode.controlledConcentration,
          DisciplineReasonCode.controlledTradingFrequency,
        ],
      );

      final response = FallbackCoach.analyze(context);

      expect(response.aiProvider, equals('DeterministicFallback'));
      expect(response.modelId, equals('deterministic-v1'));
      expect(response.promptVersion, equals('fallback-v1'));
      expect(response.latencyMs, equals(0));
      expect(response.whatDoneWell, contains('stop-loss protection'));
      expect(response.whatDoneWell,
          contains('Position size was kept within recommended allocation'));
      expect(response.whatIncreasedRisk,
          contains('No critical risk warnings detected'));
    });

    test(
        'Adverse behavior emits clear educational warnings in whatIncreasedRisk',
        () {
      final context = CoachContextBuilder.build(
        symbol: 'SOL',
        side: TradeSide.buy,
        quantity: 50.0,
        executionPriceInr: 15000.0,
        totalTradeValueInr: 750000.0,
        hasStopLoss: false,
        totalEquityInr: 1000000.0,
        virtualCashBalanceInr: 250000.0,
        riskScore: highRiskScore,
        disciplineScore: lowDisciplineScore,
        riskReasonCodes: const [
          RiskReasonCode.highConcentration,
          RiskReasonCode.largePositionSize,
          RiskReasonCode.elevatedVolatility,
          RiskReasonCode.noStopLoss,
        ],
        disciplineReasonCodes: const [
          DisciplineReasonCode.poorRiskManagement,
          DisciplineReasonCode.excessivePositionSize,
          DisciplineReasonCode.missingStopLoss,
          DisciplineReasonCode.highConcentration,
          DisciplineReasonCode.highTradingFrequency,
        ],
      );

      final response = FallbackCoach.analyze(context);

      expect(
          response.whatIncreasedRisk, contains('without stop-loss protection'));
      expect(response.whatIncreasedRisk,
          contains('Position size allocation exceeds recommended risk limits'));
      expect(
          response.whatIncreasedRisk, contains('High portfolio concentration'));
      expect(response.whatIncreasedRisk,
          contains('Elevated 24-hour trading frequency'));
      expect(response.whatToConsiderNext, contains('stop-loss order'));
    });

    test(
        'Mixed behavior acknowledges positive aspects while providing adverse warnings',
        () {
      final context = CoachContextBuilder.build(
        symbol: 'ETH',
        side: TradeSide.buy,
        quantity: 2.0,
        executionPriceInr: 250000.0,
        totalTradeValueInr: 500000.0,
        hasStopLoss: true,
        stopLossPriceInr: 240000.0,
        totalEquityInr: 800000.0,
        virtualCashBalanceInr: 300000.0,
        riskScore: highRiskScore,
        disciplineScore: lowDisciplineScore,
        riskReasonCodes: const [
          RiskReasonCode.highConcentration,
          RiskReasonCode.largePositionSize,
          RiskReasonCode.normalVolatility,
          RiskReasonCode.stopLossPresent,
        ],
        disciplineReasonCodes: const [
          DisciplineReasonCode.poorRiskManagement,
          DisciplineReasonCode.excessivePositionSize,
          DisciplineReasonCode.usedStopLoss,
          DisciplineReasonCode.highConcentration,
          DisciplineReasonCode.controlledTradingFrequency,
        ],
      );

      final response = FallbackCoach.analyze(context);

      // Positive stop-loss behavior acknowledged in whatDoneWell
      expect(response.whatDoneWell, contains('stop-loss protection'));

      // Adverse position size & concentration warned in whatIncreasedRisk
      expect(response.whatIncreasedRisk,
          contains('Position size allocation exceeds'));
      expect(
          response.whatIncreasedRisk, contains('High portfolio concentration'));
    });

    test(
        'RiskLevel summary adapts correctly across LOW, MODERATE, HIGH, EXTREME',
        () {
      final lowCtx = CoachContextBuilder.build(
        symbol: 'BTC',
        side: TradeSide.buy,
        quantity: 0.01,
        executionPriceInr: 5000000.0,
        totalTradeValueInr: 50000.0,
        hasStopLoss: true,
        totalEquityInr: 1000000.0,
        virtualCashBalanceInr: 950000.0,
        riskScore: lowRiskScore,
        disciplineScore: highDisciplineScore,
        riskReasonCodes: const [RiskReasonCode.stopLossPresent],
        disciplineReasonCodes: const [DisciplineReasonCode.usedStopLoss],
      );
      final modCtx = CoachContextBuilder.build(
        symbol: 'BTC',
        side: TradeSide.buy,
        quantity: 0.05,
        executionPriceInr: 5000000.0,
        totalTradeValueInr: 250000.0,
        hasStopLoss: true,
        totalEquityInr: 1000000.0,
        virtualCashBalanceInr: 750000.0,
        riskScore: moderateRiskScore,
        disciplineScore: highDisciplineScore,
        riskReasonCodes: const [RiskReasonCode.stopLossPresent],
        disciplineReasonCodes: const [DisciplineReasonCode.usedStopLoss],
      );
      final highCtx = CoachContextBuilder.build(
        symbol: 'BTC',
        side: TradeSide.buy,
        quantity: 0.1,
        executionPriceInr: 5000000.0,
        totalTradeValueInr: 500000.0,
        hasStopLoss: false,
        totalEquityInr: 1000000.0,
        virtualCashBalanceInr: 500000.0,
        riskScore: highRiskScore,
        disciplineScore: lowDisciplineScore,
        riskReasonCodes: const [RiskReasonCode.noStopLoss],
        disciplineReasonCodes: const [DisciplineReasonCode.missingStopLoss],
      );
      final extremeCtx = CoachContextBuilder.build(
        symbol: 'BTC',
        side: TradeSide.buy,
        quantity: 0.18,
        executionPriceInr: 5000000.0,
        totalTradeValueInr: 900000.0,
        hasStopLoss: false,
        totalEquityInr: 1000000.0,
        virtualCashBalanceInr: 100000.0,
        riskScore: extremeRiskScore,
        disciplineScore: lowDisciplineScore,
        riskReasonCodes: const [RiskReasonCode.noStopLoss],
        disciplineReasonCodes: const [DisciplineReasonCode.missingStopLoss],
      );

      expect(FallbackCoach.analyze(lowCtx).whatToLearn, contains('LOW'));
      expect(FallbackCoach.analyze(modCtx).whatToLearn, contains('MODERATE'));
      expect(FallbackCoach.analyze(highCtx).whatToLearn, contains('HIGH'));
      expect(
          FallbackCoach.analyze(extremeCtx).whatToLearn, contains('EXTREME'));
    });

    test('FallbackCoach output is strictly deterministic for identical context',
        () {
      final context = CoachContextBuilder.build(
        symbol: 'XRP',
        side: TradeSide.buy,
        quantity: 1000.0,
        executionPriceInr: 100.0,
        totalTradeValueInr: 100000.0,
        hasStopLoss: false,
        totalEquityInr: 500000.0,
        virtualCashBalanceInr: 400000.0,
        riskScore: moderateRiskScore,
        disciplineScore: lowDisciplineScore,
        riskReasonCodes: const [
          RiskReasonCode.balancedConcentration,
          RiskReasonCode.controlledPositionSize,
          RiskReasonCode.normalVolatility,
          RiskReasonCode.noStopLoss,
        ],
        disciplineReasonCodes: const [
          DisciplineReasonCode.goodRiskManagement,
          DisciplineReasonCode.disciplinedPositionSize,
          DisciplineReasonCode.missingStopLoss,
          DisciplineReasonCode.controlledConcentration,
          DisciplineReasonCode.controlledTradingFrequency,
        ],
      );

      final r1 = FallbackCoach.analyze(context);
      final r2 = FallbackCoach.analyze(context);

      expect(r1.whatDoneWell, equals(r2.whatDoneWell));
      expect(r1.whatIncreasedRisk, equals(r2.whatIncreasedRisk));
      expect(r1.whatToLearn, equals(r2.whatToLearn));
      expect(r1.whatToConsiderNext, equals(r2.whatToConsiderNext));
    });

    test(
        'Profit independence: Feedback depends purely on process/reason codes, not profitability',
        () {
      final context = CoachContextBuilder.build(
        symbol: 'BTC',
        side: TradeSide.buy,
        quantity: 0.01,
        executionPriceInr: 5000000.0,
        totalTradeValueInr: 50000.0,
        hasStopLoss: true,
        totalEquityInr: 1000000.0,
        virtualCashBalanceInr: 950000.0,
        riskScore: lowRiskScore,
        disciplineScore: highDisciplineScore,
        riskReasonCodes: const [
          RiskReasonCode.stopLossPresent,
          RiskReasonCode.controlledPositionSize,
        ],
        disciplineReasonCodes: const [
          DisciplineReasonCode.usedStopLoss,
          DisciplineReasonCode.disciplinedPositionSize,
        ],
      );

      final response = FallbackCoach.analyze(context);

      // Verify no profitability claims in response
      expect(response.whatDoneWell, contains('stop-loss protection'));
      expect(response.whatDoneWell.toLowerCase(), isNot(contains('profit')));
      expect(response.whatDoneWell.toLowerCase(), isNot(contains('gain')));
      expect(
          response.whatIncreasedRisk.toLowerCase(), isNot(contains('profit')));
    });

    test(
        'AI Safety language checks: Response contains no prohibited financial advice or return guarantees',
        () {
      final context = CoachContextBuilder.build(
        symbol: 'ETH',
        side: TradeSide.buy,
        quantity: 1.0,
        executionPriceInr: 250000.0,
        totalTradeValueInr: 250000.0,
        hasStopLoss: false,
        totalEquityInr: 500000.0,
        virtualCashBalanceInr: 250000.0,
        riskScore: highRiskScore,
        disciplineScore: lowDisciplineScore,
        riskReasonCodes: const [RiskReasonCode.noStopLoss],
        disciplineReasonCodes: const [DisciplineReasonCode.missingStopLoss],
      );

      final response = FallbackCoach.analyze(context);
      final fullText =
          '${response.whatDoneWell} ${response.whatIncreasedRisk} ${response.whatToLearn} ${response.whatToConsiderNext}'
              .toLowerCase();

      expect(fullText, isNot(contains('guaranteed')));
      expect(fullText, isNot(contains('will profit')));
      expect(fullText, isNot(contains('safe investment')));
      expect(fullText, isNot(contains('trade real money')));
      expect(fullText, isNot(contains('ready for real trading')));
    });
  });
}
