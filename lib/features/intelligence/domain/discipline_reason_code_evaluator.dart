import 'package:flutter/foundation.dart';
import '../../../core/utils/discipline_calculator.dart';
import '../../../shared/models/discipline_score.dart';
import '../../../shared/models/risk_score.dart';
import 'reason_code.dart';

/// Domain result pairing established DisciplineScore with machine-readable reason codes.
@immutable
class DisciplineAnalysisResult {
  final DisciplineScore score;
  final List<DisciplineReasonCode> reasonCodes;

  const DisciplineAnalysisResult({
    required this.score,
    required this.reasonCodes,
  });

  /// Convenience getter for machine-readable string codes.
  List<String> get reasonCodeStrings => reasonCodes.map((r) => r.code).toList();
}

/// Evaluator that produces deterministic machine-readable DisciplineReasonCodes.
class DisciplineReasonCodeEvaluator {
  /// Evaluates deterministic reason codes matching established calculator thresholds.
  static List<DisciplineReasonCode> evaluate({
    required RiskScore currentRiskScore,
    required double positionSizePercentage,
    required bool usedStopLoss,
    required double portfolioConcentration,
    required int tradeFrequency24h,
    required DisciplineScore score,
  }) {
    final codes = <DisciplineReasonCode>[];

    // 1. Risk Management (> 60 risk score indicates high/extreme portfolio risk)
    if (currentRiskScore.score > 60) {
      codes.add(DisciplineReasonCode.poorRiskManagement);
    } else {
      codes.add(DisciplineReasonCode.goodRiskManagement);
    }

    // 2. Position Sizing (> 10% of equity is penalized by formula)
    if (positionSizePercentage > 10.0) {
      codes.add(DisciplineReasonCode.excessivePositionSize);
    } else {
      codes.add(DisciplineReasonCode.disciplinedPositionSize);
    }

    // 3. Stop Loss Discipline
    if (usedStopLoss) {
      codes.add(DisciplineReasonCode.usedStopLoss);
    } else {
      codes.add(DisciplineReasonCode.missingStopLoss);
    }

    // 4. Portfolio Concentration Control (> 50%)
    if (portfolioConcentration > 50.0) {
      codes.add(DisciplineReasonCode.highConcentration);
    } else {
      codes.add(DisciplineReasonCode.controlledConcentration);
    }

    // 5. Frequency Control (> 5 trades per 24h is penalized by formula)
    if (tradeFrequency24h > 5) {
      codes.add(DisciplineReasonCode.highTradingFrequency);
    } else {
      codes.add(DisciplineReasonCode.controlledTradingFrequency);
    }

    return List.unmodifiable(codes);
  }

  /// Evaluates discipline score and deterministic reason codes together.
  static DisciplineAnalysisResult analyze({
    required RiskScore currentRiskScore,
    required double positionSizePercentage,
    required bool usedStopLoss,
    required double portfolioConcentration,
    required int tradeFrequency24h,
  }) {
    final score = DisciplineCalculator.compute(
      currentRiskScore: currentRiskScore,
      positionSizePercentage: positionSizePercentage,
      usedStopLoss: usedStopLoss,
      portfolioConcentration: portfolioConcentration,
      tradeFrequency24h: tradeFrequency24h,
    );

    final codes = evaluate(
      currentRiskScore: currentRiskScore,
      positionSizePercentage: positionSizePercentage,
      usedStopLoss: usedStopLoss,
      portfolioConcentration: portfolioConcentration,
      tradeFrequency24h: tradeFrequency24h,
      score: score,
    );

    return DisciplineAnalysisResult(
      score: score,
      reasonCodes: codes,
    );
  }
}
