import '../../shared/models/portfolio.dart';
import '../../shared/models/risk_score.dart';

class RiskCalculator {
  /// Computes Portfolio Risk Score (0-100)
  /// Weights:
  /// - 40% Concentration (Single asset / Herfindahl Index)
  /// - 30% Position Sizing (Trade size as % of portfolio)
  /// - 20% Asset Volatility Exposure
  /// - 10% Stop-Loss Behaviour
  static RiskScore compute({
    required Portfolio portfolio,
    required double proposedTradeSizeInr,
    required bool hasStopLoss,
    required double assetVolatility,
  }) {
    final totalEquity = portfolio.totalPortfolioValueInr;
    final explanations = <String>[];

    // 1. Concentration Score (40%)
    double maxConcentration = 0.0;
    if (portfolio.holdings.isNotEmpty && totalEquity > 0) {
      for (final h in portfolio.holdings) {
        final share = h.currentValueInr / totalEquity;
        if (share > maxConcentration) maxConcentration = share;
      }
    }
    double concentrationRaw = (maxConcentration * 100.0).clamp(0.0, 100.0);
    if (concentrationRaw > 50.0) {
      explanations.add('High portfolio concentration: ${concentrationRaw.toStringAsFixed(1)}% in a single asset.');
    }

    // 2. Position Sizing Score (30%)
    double tradePercent = totalEquity > 0 ? (proposedTradeSizeInr / totalEquity) * 100.0 : 0.0;
    double sizingRaw = (tradePercent * 2.0).clamp(0.0, 100.0);
    if (tradePercent > 25.0) {
      explanations.add('Large position size: ${tradePercent.toStringAsFixed(1)}% of total equity allocated.');
    }

    // 3. Volatility Score (20%)
    double volatilityRaw = (assetVolatility * 10.0).clamp(0.0, 100.0);
    if (assetVolatility > 5.0) {
      explanations.add('Elevated market volatility ($assetVolatility% 24h swing).');
    }

    // 4. Stop-Loss Score (10%)
    double stopLossRaw = hasStopLoss ? 0.0 : 100.0;
    if (!hasStopLoss) {
      explanations.add('No stop-loss protection set on this trade.');
    }

    final totalScore = ((concentrationRaw * 0.40) +
            (sizingRaw * 0.30) +
            (volatilityRaw * 0.20) +
            (stopLossRaw * 0.10))
        .round()
        .clamp(0, 100);

    if (explanations.isEmpty) {
      explanations.add('Well-balanced position size and risk control.');
    }

    return RiskScore(
      score: totalScore,
      level: RiskScore.calculateLevel(totalScore),
      concentrationScore: concentrationRaw,
      sizingScore: sizingRaw,
      volatilityScore: volatilityRaw,
      stopLossScore: stopLossRaw,
      explanations: explanations,
    );
  }
}
