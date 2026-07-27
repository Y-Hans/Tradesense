import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/core/utils/risk_calculator.dart';
import 'package:cryptoedu/core/utils/discipline_calculator.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:cryptoedu/shared/models/portfolio.dart';
import 'package:cryptoedu/shared/models/risk_score.dart';

void main() {
  group('Risk & Discipline Calculators', () {
    test('RiskCalculator computes moderate score correctly', () {
      final portfolio = Portfolio(
        wallet: VirtualWallet.initial(),
        holdings: const [],
        totalRealisedPnlInr: 0.0,
      );

      final risk = RiskCalculator.compute(
        portfolio: portfolio,
        proposedTradeSizeInr: 20000.0, // 20% of equity
        hasStopLoss: true,
        assetVolatility: 3.0,
      );

      expect(risk.score, isNotNull);
      expect(risk.score, greaterThanOrEqualTo(0));
      expect(risk.score, lessThanOrEqualTo(100));
      expect(risk.stopLossScore, 0.0);
    });

    test('DisciplineCalculator rewards stop-loss usage independent of profit', () {
      const riskScore = RiskScore(
        score: 30,
        level: RiskLevel.low,
        concentrationScore: 10,
        sizingScore: 20,
        volatilityScore: 10,
        stopLossScore: 0,
        explanations: [],
      );

      final disciplineWithStopLoss = DisciplineCalculator.compute(
        currentRiskScore: riskScore,
        positionSizePercentage: 10.0,
        usedStopLoss: true,
        portfolioConcentration: 10.0,
        tradeFrequency24h: 2,
      );

      final disciplineWithoutStopLoss = DisciplineCalculator.compute(
        currentRiskScore: riskScore,
        positionSizePercentage: 10.0,
        usedStopLoss: false,
        portfolioConcentration: 10.0,
        tradeFrequency24h: 2,
      );

      expect(disciplineWithStopLoss.score, greaterThan(disciplineWithoutStopLoss.score));
    });
  });
}
