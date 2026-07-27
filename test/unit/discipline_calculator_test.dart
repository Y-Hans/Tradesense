import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/core/utils/discipline_calculator.dart';
import 'package:cryptoedu/shared/models/risk_score.dart';

void main() {
  group('DisciplineCalculator Unit Tests', () {
    const lowRiskScore = RiskScore(
      score: 20,
      level: RiskLevel.low,
      concentrationScore: 10,
      sizingScore: 10,
      volatilityScore: 20,
      stopLossScore: 0,
      explanations: ['Low risk'],
    );

    const highRiskScore = RiskScore(
      score: 80,
      level: RiskLevel.high,
      concentrationScore: 80,
      sizingScore: 80,
      volatilityScore: 50,
      stopLossScore: 100,
      explanations: ['High risk'],
    );

    test('Disciplined behavior scores high across all 5 components', () {
      final discipline = DisciplineCalculator.compute(
        currentRiskScore: lowRiskScore,
        positionSizePercentage: 8.0, // <= 10% -> 100.0 score
        usedStopLoss: true, // 100.0 score
        portfolioConcentration: 10.0, // 90.0 score
        tradeFrequency24h: 3, // <= 5 -> 100.0 score
      );

      expect(discipline.score, greaterThanOrEqualTo(85));
      expect(discipline.riskMgmtScore, 80.0); // 100 - 20
      expect(discipline.positionSizingScore, 100.0);
      expect(discipline.stopLossDisciplineScore, 100.0);
      expect(discipline.concentrationScore, 90.0);
      expect(discipline.frequencyScore, 100.0);
      expect(
        discipline.breakdownNotes,
        contains('Used a protective stop-loss to manage downside risk.'),
      );
      expect(
        discipline.breakdownNotes,
        contains('Disciplined position sizing (<= 20% of equity).'),
      );
    });

    test('Poor risk management (> 60 risk score) penalizes discipline score',
        () {
      final disciplineLowRisk = DisciplineCalculator.compute(
        currentRiskScore: lowRiskScore,
        positionSizePercentage: 10.0,
        usedStopLoss: true,
        portfolioConcentration: 10.0,
        tradeFrequency24h: 2,
      );

      final disciplineHighRisk = DisciplineCalculator.compute(
        currentRiskScore: highRiskScore,
        positionSizePercentage: 10.0,
        usedStopLoss: true,
        portfolioConcentration: 10.0,
        tradeFrequency24h: 2,
      );

      expect(disciplineHighRisk.riskMgmtScore, 20.0); // 100 - 80
      expect(disciplineHighRisk.score, lessThan(disciplineLowRisk.score));
    });

    test('Excessive position sizing (> 20%) triggers penalty and note', () {
      final disciplineControlled = DisciplineCalculator.compute(
        currentRiskScore: lowRiskScore,
        positionSizePercentage: 15.0,
        usedStopLoss: true,
        portfolioConcentration: 10.0,
        tradeFrequency24h: 2,
      );

      final disciplineExcessive = DisciplineCalculator.compute(
        currentRiskScore: lowRiskScore,
        positionSizePercentage: 30.0, // > 20% penalty
        usedStopLoss: true,
        portfolioConcentration: 10.0,
        tradeFrequency24h: 2,
      );

      expect(disciplineExcessive.positionSizingScore,
          lessThan(disciplineControlled.positionSizingScore));
      expect(
        disciplineExcessive.breakdownNotes,
        contains('Excessive position sizing reduces discipline rating.'),
      );
    });

    test('Stop-loss usage provides 20-point component advantage', () {
      final withStopLoss = DisciplineCalculator.compute(
        currentRiskScore: lowRiskScore,
        positionSizePercentage: 10.0,
        usedStopLoss: true,
        portfolioConcentration: 10.0,
        tradeFrequency24h: 2,
      );

      final withoutStopLoss = DisciplineCalculator.compute(
        currentRiskScore: lowRiskScore,
        positionSizePercentage: 10.0,
        usedStopLoss: false,
        portfolioConcentration: 10.0,
        tradeFrequency24h: 2,
      );

      expect(withStopLoss.stopLossDisciplineScore, 100.0);
      expect(withoutStopLoss.stopLossDisciplineScore, 0.0);
      expect(withStopLoss.score - withoutStopLoss.score,
          20); // 20% weight * 100 pts
      expect(
        withoutStopLoss.breakdownNotes,
        contains('Executed trade without stop-loss protection (-20 pts).'),
      );
    });

    test('High 24h trading frequency (> 10 trades) penalizes over-trading', () {
      final normalFreq = DisciplineCalculator.compute(
        currentRiskScore: lowRiskScore,
        positionSizePercentage: 10.0,
        usedStopLoss: true,
        portfolioConcentration: 10.0,
        tradeFrequency24h: 4,
      );

      final highFreq = DisciplineCalculator.compute(
        currentRiskScore: lowRiskScore,
        positionSizePercentage: 10.0,
        usedStopLoss: true,
        portfolioConcentration: 10.0,
        tradeFrequency24h: 15,
      );

      expect(highFreq.frequencyScore, lessThan(normalFreq.frequencyScore));
      expect(
        highFreq.breakdownNotes,
        contains(
            'High trading frequency indicates potential over-trading/FOMO.'),
      );
    });

    test('Discipline score is strictly bounded within 0 to 100', () {
      final worstDiscipline = DisciplineCalculator.compute(
        currentRiskScore: const RiskScore(
          score: 100,
          level: RiskLevel.extreme,
          concentrationScore: 100,
          sizingScore: 100,
          volatilityScore: 100,
          stopLossScore: 100,
          explanations: [],
        ),
        positionSizePercentage: 50.0,
        usedStopLoss: false,
        portfolioConcentration: 100.0,
        tradeFrequency24h: 20,
      );

      expect(worstDiscipline.score, 0);

      final bestDiscipline = DisciplineCalculator.compute(
        currentRiskScore: const RiskScore(
          score: 0,
          level: RiskLevel.low,
          concentrationScore: 0,
          sizingScore: 0,
          volatilityScore: 0,
          stopLossScore: 0,
          explanations: [],
        ),
        positionSizePercentage: 5.0,
        usedStopLoss: true,
        portfolioConcentration: 0.0,
        tradeFrequency24h: 1,
      );

      expect(bestDiscipline.score, 100);
    });

    test(
        'Profit independence: Discipline depends purely on process/behavior inputs',
        () {
      // Reckless trade inputs: no stop loss, excessive position sizing (35%), overtrading (12 trades)
      final recklessTradeDiscipline = DisciplineCalculator.compute(
        currentRiskScore: highRiskScore,
        positionSizePercentage: 35.0,
        usedStopLoss: false,
        portfolioConcentration: 70.0,
        tradeFrequency24h: 12,
      );

      // Controlled trade inputs: used stop loss, disciplined position size (8%), low frequency (2 trades)
      final controlledTradeDiscipline = DisciplineCalculator.compute(
        currentRiskScore: lowRiskScore,
        positionSizePercentage: 8.0,
        usedStopLoss: true,
        portfolioConcentration: 15.0,
        tradeFrequency24h: 2,
      );

      // Reckless process receives low discipline rating regardless of trade outcome
      expect(recklessTradeDiscipline.score, lessThan(40));

      // Controlled process receives high discipline rating regardless of trade outcome
      expect(controlledTradeDiscipline.score, greaterThan(85));
    });
  });
}
