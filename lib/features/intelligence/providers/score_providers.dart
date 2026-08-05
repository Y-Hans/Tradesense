import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/intelligence/domain/risk_reason_code_evaluator.dart';
import '../../../features/intelligence/domain/discipline_reason_code_evaluator.dart';

/// Consolidated score data for the dashboard UI.
@immutable
class PortfolioScores {
  final int disciplineScore;
  final int riskScore;
  final String disciplineLabel;
  final String riskLabel;

  const PortfolioScores({
    required this.disciplineScore,
    required this.riskScore,
    required this.disciplineLabel,
    required this.riskLabel,
  });
}

/// Computes real-time discipline and risk scores using Yajat's intelligence
/// layer (IntelligenceRepository / evaluators) over the current portfolio.
///
/// Integration Point (Yajat): This provider uses the domain evaluators
/// directly. When the IntelligenceRepository gains async support, replace the
/// direct evaluator calls with ref.watch(intelligenceRepositoryProvider).
final portfolioScoresProvider = FutureProvider<PortfolioScores>((ref) async {
  final portfolio = await ref.watch(portfolioProvider.future);
  final tradingRepo = ref.watch(tradingRepositoryProvider);
  final history = await tradingRepo.getTradeHistory();

  final hasAnyTrade = history.isNotEmpty;
  final lastTrade = hasAnyTrade ? history.first : null;
  final hasStopLoss = lastTrade?.stopLossPriceInr != null;

  // Calculate risk score using Yajat's domain evaluator
  final lastTradeSize = lastTrade?.totalAmountInr ??
      portfolio.totalPortfolioValueInr * 0.10; // Default to 10% position
  final riskResult = RiskReasonCodeEvaluator.analyze(
    portfolio: portfolio,
    proposedTradeSizeInr: lastTradeSize,
    hasStopLoss: hasStopLoss,
    assetVolatility: 3.5, // Moderate crypto volatility assumption
  );

  // Calculate discipline score using Yajat's domain evaluator
  final positionSizePct = portfolio.totalPortfolioValueInr > 0
      ? (lastTradeSize / portfolio.totalPortfolioValueInr) * 100.0
      : 10.0;

  double maxConcentration = 0.0;
  if (portfolio.holdings.isNotEmpty && portfolio.totalPortfolioValueInr > 0) {
    for (final h in portfolio.holdings) {
      final share = (h.currentValueInr / portfolio.totalPortfolioValueInr) * 100.0;
      if (share > maxConcentration) maxConcentration = share;
    }
  }

  final disciplineResult = DisciplineReasonCodeEvaluator.analyze(
    currentRiskScore: riskResult.score,
    positionSizePercentage: positionSizePct,
    usedStopLoss: hasStopLoss,
    portfolioConcentration: maxConcentration,
    tradeFrequency24h: history.length,
  );

  final riskScore = riskResult.score.score;
  final disciplineScore = disciplineResult.score.score;

  return PortfolioScores(
    disciplineScore: disciplineScore,
    riskScore: riskScore,
    disciplineLabel: _disciplineLabel(disciplineScore),
    riskLabel: _riskLabel(riskScore),
  );
});

String _disciplineLabel(int score) {
  if (score >= 85) return 'Excellent process';
  if (score >= 70) return 'Good discipline';
  if (score >= 50) return 'Room to improve';
  return 'Needs attention';
}

String _riskLabel(int score) {
  if (score <= 30) return 'Low risk';
  if (score <= 60) return 'Moderate risk';
  if (score <= 80) return 'High risk';
  return 'Extreme risk';
}
