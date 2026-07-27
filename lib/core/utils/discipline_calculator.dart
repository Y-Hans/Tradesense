import '../../shared/models/risk_score.dart';
import '../../shared/models/discipline_score.dart';

class DisciplineCalculator {
  /// Computes Trading Discipline Score (0-100)
  /// PRIMARY PHILOSOPHY: Profit is NOT an input! Process is rewarded.
  /// Weights:
  /// - 30% Risk Management Adherence
  /// - 25% Position Sizing Discipline
  /// - 20% Stop-Loss Usage
  /// - 15% Portfolio Concentration Control
  /// - 10% Trading Frequency (Over-trading penalty)
  static DisciplineScore compute({
    required RiskScore currentRiskScore,
    required double positionSizePercentage,
    required bool usedStopLoss,
    required double portfolioConcentration,
    required int tradeFrequency24h,
  }) {
    final notes = <String>[];

    // 1. Risk Management (30%)
    double riskMgmtRaw =
        (100.0 - currentRiskScore.score.toDouble()).clamp(0.0, 100.0);

    // 2. Position Sizing (25%)
    double positionSizingRaw = positionSizePercentage <= 10.0
        ? 100.0
        : (100.0 - (positionSizePercentage - 10.0) * 4.0).clamp(0.0, 100.0);
    if (positionSizePercentage > 20.0) {
      notes.add('Excessive position sizing reduces discipline rating.');
    } else {
      notes.add('Disciplined position sizing (<= 20% of equity).');
    }

    // 3. Stop-Loss Discipline (20%)
    double stopLossRaw = usedStopLoss ? 100.0 : 0.0;
    if (usedStopLoss) {
      notes.add('Used a protective stop-loss to manage downside risk.');
    } else {
      notes.add('Executed trade without stop-loss protection (-20 pts).');
    }

    // 4. Portfolio Concentration (15%)
    double concentrationRaw =
        (100.0 - portfolioConcentration).clamp(0.0, 100.0);

    // 5. Frequency Control (10%)
    double frequencyRaw = tradeFrequency24h <= 5
        ? 100.0
        : (100.0 - (tradeFrequency24h - 5) * 15.0).clamp(0.0, 100.0);
    if (tradeFrequency24h > 10) {
      notes
          .add('High trading frequency indicates potential over-trading/FOMO.');
    }

    final totalScore = ((riskMgmtRaw * 0.30) +
            (positionSizingRaw * 0.25) +
            (stopLossRaw * 0.20) +
            (concentrationRaw * 0.15) +
            (frequencyRaw * 0.10))
        .round()
        .clamp(0, 100);

    return DisciplineScore(
      score: totalScore,
      riskMgmtScore: riskMgmtRaw,
      positionSizingScore: positionSizingRaw,
      stopLossDisciplineScore: stopLossRaw,
      concentrationScore: concentrationRaw,
      frequencyScore: frequencyRaw,
      breakdownNotes: notes,
    );
  }
}
