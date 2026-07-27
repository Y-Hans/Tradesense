import 'package:flutter/foundation.dart';
import '../../../core/utils/risk_calculator.dart';
import '../../../shared/models/portfolio.dart';
import '../../../shared/models/risk_score.dart';
import 'reason_code.dart';

/// Domain result pairing established RiskScore with machine-readable reason codes.
@immutable
class RiskAnalysisResult {
  final RiskScore score;
  final List<RiskReasonCode> reasonCodes;

  const RiskAnalysisResult({
    required this.score,
    required this.reasonCodes,
  });

  /// Convenience getter for machine-readable string codes.
  List<String> get reasonCodeStrings => reasonCodes.map((r) => r.code).toList();
}

/// Evaluator that produces deterministic machine-readable RiskReasonCodes.
class RiskReasonCodeEvaluator {
  /// Evaluates deterministic reason codes matching established calculator thresholds.
  static List<RiskReasonCode> evaluate({
    required Portfolio portfolio,
    required double proposedTradeSizeInr,
    required bool hasStopLoss,
    required double assetVolatility,
    required RiskScore score,
  }) {
    final codes = <RiskReasonCode>[];

    // 1. Concentration (> 50%)
    if (score.concentrationScore > 50.0) {
      codes.add(RiskReasonCode.highConcentration);
    } else {
      codes.add(RiskReasonCode.balancedConcentration);
    }

    // 2. Position Sizing (> 25% of equity)
    final totalEquity = portfolio.totalPortfolioValueInr;
    final tradePercent =
        totalEquity > 0 ? (proposedTradeSizeInr / totalEquity) * 100.0 : 0.0;
    if (tradePercent > 25.0) {
      codes.add(RiskReasonCode.largePositionSize);
    } else {
      codes.add(RiskReasonCode.controlledPositionSize);
    }

    // 3. Volatility (> 5.0%)
    if (assetVolatility > 5.0) {
      codes.add(RiskReasonCode.elevatedVolatility);
    } else {
      codes.add(RiskReasonCode.normalVolatility);
    }

    // 4. Stop Loss
    if (!hasStopLoss) {
      codes.add(RiskReasonCode.noStopLoss);
    } else {
      codes.add(RiskReasonCode.stopLossPresent);
    }

    return List.unmodifiable(codes);
  }

  /// Evaluates risk score and deterministic reason codes together.
  static RiskAnalysisResult analyze({
    required Portfolio portfolio,
    required double proposedTradeSizeInr,
    required bool hasStopLoss,
    required double assetVolatility,
  }) {
    final score = RiskCalculator.compute(
      portfolio: portfolio,
      proposedTradeSizeInr: proposedTradeSizeInr,
      hasStopLoss: hasStopLoss,
      assetVolatility: assetVolatility,
    );

    final codes = evaluate(
      portfolio: portfolio,
      proposedTradeSizeInr: proposedTradeSizeInr,
      hasStopLoss: hasStopLoss,
      assetVolatility: assetVolatility,
      score: score,
    );

    return RiskAnalysisResult(
      score: score,
      reasonCodes: codes,
    );
  }
}
