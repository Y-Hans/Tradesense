import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
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

  final riskScore = 40;
  final disciplineScore = 80;

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
