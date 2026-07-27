import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/features/intelligence/domain/reason_code.dart';
import 'package:cryptoedu/features/intelligence/domain/risk_reason_code_evaluator.dart';
import 'package:cryptoedu/features/intelligence/domain/discipline_reason_code_evaluator.dart';
import 'package:cryptoedu/shared/models/portfolio.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:cryptoedu/shared/models/holding.dart';
import 'package:cryptoedu/shared/models/risk_score.dart';
import 'package:cryptoedu/shared/models/discipline_score.dart';

void main() {
  group('Reason Code System Unit Tests', () {
    const lowRisk = RiskScore(
      score: 20,
      level: RiskLevel.low,
      concentrationScore: 10,
      sizingScore: 10,
      volatilityScore: 20,
      stopLossScore: 0,
      explanations: [],
    );

    const highRisk = RiskScore(
      score: 75,
      level: RiskLevel.high,
      concentrationScore: 70,
      sizingScore: 60,
      volatilityScore: 60,
      stopLossScore: 100,
      explanations: [],
    );

    final balancedPortfolio = Portfolio(
      wallet: VirtualWallet.initial(),
      holdings: const [],
      totalRealisedPnlInr: 0.0,
    );

    const concentratedPortfolio = Portfolio(
      wallet: VirtualWallet(balanceInr: 20000.0, lockedInr: 0.0),
      holdings: [
        Holding(
          id: 'h1',
          userId: 'user1',
          symbol: 'BTC',
          quantity: 1.0,
          averageEntryPriceInr: 80000.0,
          currentPriceInr: 80000.0,
        ),
      ],
      totalRealisedPnlInr: 0.0,
    );

    test('RiskReasonCode enum serialization stability', () {
      expect(RiskReasonCode.highConcentration.code, 'CONCENTRATION_HIGH');
      expect(
          RiskReasonCode.balancedConcentration.code, 'CONCENTRATION_BALANCED');
      expect(RiskReasonCode.largePositionSize.code, 'POSITION_SIZE_LARGE');
      expect(RiskReasonCode.controlledPositionSize.code,
          'POSITION_SIZE_CONTROLLED');
      expect(RiskReasonCode.elevatedVolatility.code, 'VOLATILITY_ELEVATED');
      expect(RiskReasonCode.normalVolatility.code, 'VOLATILITY_NORMAL');
      expect(RiskReasonCode.noStopLoss.code, 'NO_STOP_LOSS');
      expect(RiskReasonCode.stopLossPresent.code, 'STOP_LOSS_PRESENT');

      expect(RiskReasonCode.fromCode('CONCENTRATION_HIGH'),
          RiskReasonCode.highConcentration);
      expect(
          RiskReasonCode.fromCode('NO_STOP_LOSS'), RiskReasonCode.noStopLoss);
    });

    test('DisciplineReasonCode enum serialization stability', () {
      expect(
          DisciplineReasonCode.poorRiskManagement.code, 'RISK_MANAGEMENT_POOR');
      expect(
          DisciplineReasonCode.goodRiskManagement.code, 'RISK_MANAGEMENT_GOOD');
      expect(DisciplineReasonCode.excessivePositionSize.code,
          'POSITION_SIZE_EXCESSIVE');
      expect(DisciplineReasonCode.disciplinedPositionSize.code,
          'POSITION_SIZE_DISCIPLINED');
      expect(DisciplineReasonCode.missingStopLoss.code, 'NO_STOP_LOSS');
      expect(DisciplineReasonCode.usedStopLoss.code, 'STOP_LOSS_USED');
      expect(DisciplineReasonCode.highConcentration.code, 'CONCENTRATION_HIGH');
      expect(DisciplineReasonCode.controlledConcentration.code,
          'CONCENTRATION_CONTROLLED');
      expect(DisciplineReasonCode.highTradingFrequency.code,
          'TRADING_FREQUENCY_HIGH');
      expect(DisciplineReasonCode.controlledTradingFrequency.code,
          'TRADING_FREQUENCY_CONTROLLED');

      expect(DisciplineReasonCode.fromCode('RISK_MANAGEMENT_POOR'),
          DisciplineReasonCode.poorRiskManagement);
      expect(DisciplineReasonCode.fromCode('STOP_LOSS_USED'),
          DisciplineReasonCode.usedStopLoss);
    });

    test('RiskReasonCodeEvaluator emits expected codes for adverse conditions',
        () {
      final result = RiskReasonCodeEvaluator.analyze(
        portfolio: concentratedPortfolio,
        proposedTradeSizeInr: 40000.0, // 40% trade size -> POSITION_SIZE_LARGE
        hasStopLoss: false, // NO_STOP_LOSS
        assetVolatility: 8.0, // VOLATILITY_ELEVATED
      );

      expect(result.reasonCodes, contains(RiskReasonCode.highConcentration));
      expect(result.reasonCodes, contains(RiskReasonCode.largePositionSize));
      expect(result.reasonCodes, contains(RiskReasonCode.elevatedVolatility));
      expect(result.reasonCodes, contains(RiskReasonCode.noStopLoss));

      // Mutually exclusive checks
      expect(result.reasonCodes,
          isNot(contains(RiskReasonCode.balancedConcentration)));
      expect(result.reasonCodes,
          isNot(contains(RiskReasonCode.controlledPositionSize)));
      expect(
          result.reasonCodes, isNot(contains(RiskReasonCode.normalVolatility)));
      expect(
          result.reasonCodes, isNot(contains(RiskReasonCode.stopLossPresent)));

      expect(result.reasonCodeStrings, contains('CONCENTRATION_HIGH'));
      expect(result.reasonCodeStrings, contains('NO_STOP_LOSS'));
    });

    test(
        'RiskReasonCodeEvaluator emits expected codes for controlled conditions',
        () {
      final result = RiskReasonCodeEvaluator.analyze(
        portfolio: balancedPortfolio,
        proposedTradeSizeInr:
            5000.0, // 5% trade size -> POSITION_SIZE_CONTROLLED
        hasStopLoss: true, // STOP_LOSS_PRESENT
        assetVolatility: 2.0, // VOLATILITY_NORMAL
      );

      expect(
          result.reasonCodes, contains(RiskReasonCode.balancedConcentration));
      expect(
          result.reasonCodes, contains(RiskReasonCode.controlledPositionSize));
      expect(result.reasonCodes, contains(RiskReasonCode.normalVolatility));
      expect(result.reasonCodes, contains(RiskReasonCode.stopLossPresent));

      // Mutually exclusive checks
      expect(result.reasonCodes,
          isNot(contains(RiskReasonCode.highConcentration)));
      expect(result.reasonCodes,
          isNot(contains(RiskReasonCode.largePositionSize)));
      expect(result.reasonCodes,
          isNot(contains(RiskReasonCode.elevatedVolatility)));
      expect(result.reasonCodes, isNot(contains(RiskReasonCode.noStopLoss)));
    });

    test(
        'DisciplineReasonCodeEvaluator emits expected codes for adverse conditions',
        () {
      final result = DisciplineReasonCodeEvaluator.analyze(
        currentRiskScore: highRisk, // RISK_MANAGEMENT_POOR
        positionSizePercentage: 30.0, // POSITION_SIZE_EXCESSIVE
        usedStopLoss: false, // NO_STOP_LOSS
        portfolioConcentration: 60.0, // CONCENTRATION_HIGH
        tradeFrequency24h: 15, // TRADING_FREQUENCY_HIGH
      );

      expect(result.reasonCodes,
          contains(DisciplineReasonCode.poorRiskManagement));
      expect(result.reasonCodes,
          contains(DisciplineReasonCode.excessivePositionSize));
      expect(
          result.reasonCodes, contains(DisciplineReasonCode.missingStopLoss));
      expect(
          result.reasonCodes, contains(DisciplineReasonCode.highConcentration));
      expect(result.reasonCodes,
          contains(DisciplineReasonCode.highTradingFrequency));

      // Mutually exclusive checks
      expect(result.reasonCodes,
          isNot(contains(DisciplineReasonCode.goodRiskManagement)));
      expect(result.reasonCodes,
          isNot(contains(DisciplineReasonCode.disciplinedPositionSize)));
      expect(result.reasonCodes,
          isNot(contains(DisciplineReasonCode.usedStopLoss)));
      expect(result.reasonCodes,
          isNot(contains(DisciplineReasonCode.controlledConcentration)));
      expect(result.reasonCodes,
          isNot(contains(DisciplineReasonCode.controlledTradingFrequency)));
    });

    test(
        'DisciplineReasonCodeEvaluator emits expected codes for disciplined conditions',
        () {
      final result = DisciplineReasonCodeEvaluator.analyze(
        currentRiskScore: lowRisk, // RISK_MANAGEMENT_GOOD
        positionSizePercentage: 10.0, // POSITION_SIZE_DISCIPLINED
        usedStopLoss: true, // STOP_LOSS_USED
        portfolioConcentration: 20.0, // CONCENTRATION_CONTROLLED
        tradeFrequency24h: 3, // TRADING_FREQUENCY_CONTROLLED
      );

      expect(result.reasonCodes,
          contains(DisciplineReasonCode.goodRiskManagement));
      expect(result.reasonCodes,
          contains(DisciplineReasonCode.disciplinedPositionSize));
      expect(result.reasonCodes, contains(DisciplineReasonCode.usedStopLoss));
      expect(result.reasonCodes,
          contains(DisciplineReasonCode.controlledConcentration));
      expect(result.reasonCodes,
          contains(DisciplineReasonCode.controlledTradingFrequency));

      // Mutually exclusive checks
      expect(result.reasonCodes,
          isNot(contains(DisciplineReasonCode.poorRiskManagement)));
      expect(result.reasonCodes,
          isNot(contains(DisciplineReasonCode.excessivePositionSize)));
      expect(result.reasonCodes,
          isNot(contains(DisciplineReasonCode.missingStopLoss)));
      expect(result.reasonCodes,
          isNot(contains(DisciplineReasonCode.highConcentration)));
      expect(result.reasonCodes,
          isNot(contains(DisciplineReasonCode.highTradingFrequency)));
    });

    group('Threshold Boundary & Contradiction Non-Regression Tests', () {
      test(
          'Discipline position sizing: <= 10.0% is full score and disciplined; > 10.0% is penalized and excessive',
          () {
        final exactBoundary = DisciplineReasonCodeEvaluator.analyze(
          currentRiskScore: lowRisk,
          positionSizePercentage: 10.0, // Exactly at 10% threshold
          usedStopLoss: true,
          portfolioConcentration: 10.0,
          tradeFrequency24h: 2,
        );

        expect(exactBoundary.score.positionSizingScore, 100.0);
        expect(exactBoundary.reasonCodes,
            contains(DisciplineReasonCode.disciplinedPositionSize));
        expect(exactBoundary.reasonCodes,
            isNot(contains(DisciplineReasonCode.excessivePositionSize)));

        final justAboveBoundary = DisciplineReasonCodeEvaluator.analyze(
          currentRiskScore: lowRisk,
          positionSizePercentage: 10.1, // Penalized by formula
          usedStopLoss: true,
          portfolioConcentration: 10.0,
          tradeFrequency24h: 2,
        );

        expect(justAboveBoundary.score.positionSizingScore, lessThan(100.0));
        expect(justAboveBoundary.reasonCodes,
            contains(DisciplineReasonCode.excessivePositionSize));
        expect(justAboveBoundary.reasonCodes,
            isNot(contains(DisciplineReasonCode.disciplinedPositionSize)));

        final midPenalized = DisciplineReasonCodeEvaluator.analyze(
          currentRiskScore: lowRisk,
          positionSizePercentage: 15.0, // 80.0 score component (penalized)
          usedStopLoss: true,
          portfolioConcentration: 10.0,
          tradeFrequency24h: 2,
        );

        expect(midPenalized.score.positionSizingScore, 80.0);
        expect(midPenalized.reasonCodes,
            contains(DisciplineReasonCode.excessivePositionSize));
        expect(midPenalized.reasonCodes,
            isNot(contains(DisciplineReasonCode.disciplinedPositionSize)));
      });

      test(
          'Discipline trading frequency: <= 5 trades is full score and controlled; > 5 trades is penalized and high',
          () {
        final exactBoundary = DisciplineReasonCodeEvaluator.analyze(
          currentRiskScore: lowRisk,
          positionSizePercentage: 8.0,
          usedStopLoss: true,
          portfolioConcentration: 10.0,
          tradeFrequency24h: 5, // Exactly 5 trades (full score)
        );

        expect(exactBoundary.score.frequencyScore, 100.0);
        expect(exactBoundary.reasonCodes,
            contains(DisciplineReasonCode.controlledTradingFrequency));
        expect(exactBoundary.reasonCodes,
            isNot(contains(DisciplineReasonCode.highTradingFrequency)));

        final justAboveBoundary = DisciplineReasonCodeEvaluator.analyze(
          currentRiskScore: lowRisk,
          positionSizePercentage: 8.0,
          usedStopLoss: true,
          portfolioConcentration: 10.0,
          tradeFrequency24h: 6, // 6 trades -> 85.0 score (penalized)
        );

        expect(justAboveBoundary.score.frequencyScore, lessThan(100.0));
        expect(justAboveBoundary.score.frequencyScore, 85.0);
        expect(justAboveBoundary.reasonCodes,
            contains(DisciplineReasonCode.highTradingFrequency));
        expect(justAboveBoundary.reasonCodes,
            isNot(contains(DisciplineReasonCode.controlledTradingFrequency)));
      });

      test(
          'Risk position sizing boundary: <= 25.0% is controlled; > 25.0% is large',
          () {
        final exactBoundary = RiskReasonCodeEvaluator.evaluate(
          portfolio: balancedPortfolio,
          proposedTradeSizeInr: 25000.0, // 25% of ₹100,000 equity
          hasStopLoss: true,
          assetVolatility: 2.0,
          score: const RiskScore(
              score: 20,
              level: RiskLevel.low,
              concentrationScore: 0,
              sizingScore: 50,
              volatilityScore: 20,
              stopLossScore: 0,
              explanations: []),
        );

        expect(exactBoundary, contains(RiskReasonCode.controlledPositionSize));
        expect(
            exactBoundary, isNot(contains(RiskReasonCode.largePositionSize)));

        final justAboveBoundary = RiskReasonCodeEvaluator.evaluate(
          portfolio: balancedPortfolio,
          proposedTradeSizeInr: 25100.0, // 25.1% of equity
          hasStopLoss: true,
          assetVolatility: 2.0,
          score: const RiskScore(
              score: 20,
              level: RiskLevel.low,
              concentrationScore: 0,
              sizingScore: 50.2,
              volatilityScore: 20,
              stopLossScore: 0,
              explanations: []),
        );

        expect(justAboveBoundary, contains(RiskReasonCode.largePositionSize));
        expect(justAboveBoundary,
            isNot(contains(RiskReasonCode.controlledPositionSize)));
      });

      test('Volatility boundary: <= 5.0% is normal; > 5.0% is elevated', () {
        final exactBoundary = RiskReasonCodeEvaluator.evaluate(
          portfolio: balancedPortfolio,
          proposedTradeSizeInr: 5000.0,
          hasStopLoss: true,
          assetVolatility: 5.0,
          score: const RiskScore(
              score: 10,
              level: RiskLevel.low,
              concentrationScore: 0,
              sizingScore: 10,
              volatilityScore: 50,
              stopLossScore: 0,
              explanations: []),
        );

        expect(exactBoundary, contains(RiskReasonCode.normalVolatility));
        expect(
            exactBoundary, isNot(contains(RiskReasonCode.elevatedVolatility)));

        final justAboveBoundary = RiskReasonCodeEvaluator.evaluate(
          portfolio: balancedPortfolio,
          proposedTradeSizeInr: 5000.0,
          hasStopLoss: true,
          assetVolatility: 5.1,
          score: const RiskScore(
              score: 10,
              level: RiskLevel.low,
              concentrationScore: 0,
              sizingScore: 10,
              volatilityScore: 51,
              stopLossScore: 0,
              explanations: []),
        );

        expect(justAboveBoundary, contains(RiskReasonCode.elevatedVolatility));
        expect(justAboveBoundary,
            isNot(contains(RiskReasonCode.normalVolatility)));
      });

      test(
          'Discipline risk management score boundary: <= 60 is good; > 60 is poor',
          () {
        final exactBoundary = DisciplineReasonCodeEvaluator.evaluate(
          currentRiskScore: const RiskScore(
            score: 60,
            level: RiskLevel.moderate,
            concentrationScore: 50,
            sizingScore: 50,
            volatilityScore: 50,
            stopLossScore: 0,
            explanations: [],
          ),
          positionSizePercentage: 8.0,
          usedStopLoss: true,
          portfolioConcentration: 10.0,
          tradeFrequency24h: 2,
          score: const DisciplineScore(
            score: 80,
            riskMgmtScore: 40,
            positionSizingScore: 100,
            stopLossDisciplineScore: 100,
            concentrationScore: 90,
            frequencyScore: 100,
            breakdownNotes: [],
          ),
        );

        expect(
            exactBoundary, contains(DisciplineReasonCode.goodRiskManagement));
        expect(exactBoundary,
            isNot(contains(DisciplineReasonCode.poorRiskManagement)));

        final justAboveBoundary = DisciplineReasonCodeEvaluator.evaluate(
          currentRiskScore: const RiskScore(
            score: 61,
            level: RiskLevel.high,
            concentrationScore: 50,
            sizingScore: 50,
            volatilityScore: 50,
            stopLossScore: 0,
            explanations: [],
          ),
          positionSizePercentage: 8.0,
          usedStopLoss: true,
          portfolioConcentration: 10.0,
          tradeFrequency24h: 2,
          score: const DisciplineScore(
            score: 79,
            riskMgmtScore: 39,
            positionSizingScore: 100,
            stopLossDisciplineScore: 100,
            concentrationScore: 90,
            frequencyScore: 100,
            breakdownNotes: [],
          ),
        );

        expect(justAboveBoundary,
            contains(DisciplineReasonCode.poorRiskManagement));
        expect(justAboveBoundary,
            isNot(contains(DisciplineReasonCode.goodRiskManagement)));
      });
    });
  });
}
