import '../../../shared/models/coach_request.dart';
import '../../../shared/models/risk_score.dart';
import '../../intelligence/domain/reason_code.dart';
import 'coach_context.dart';

/// Pure deterministic educational fallback coaching engine.
///
/// Produces educational feedback from trusted [CoachContext] facts and machine-readable
/// reason codes when generative AI is unavailable or disabled.
///
/// Does NOT call external APIs, LLMs, or network services.
class FallbackCoach {
  /// Analyzes the given [CoachContext] and produces a deterministic [CoachResponse].
  static CoachResponse analyze(CoachContext context) {
    final doneWellMessages = _extractDoneWell(context);
    final increasedRiskMessages = _extractIncreasedRisk(context);
    final learnMessage = _buildEducationalSummary(context);
    final nextMessage = _buildNextSteps(context);

    return CoachResponse(
      whatDoneWell: doneWellMessages,
      whatIncreasedRisk: increasedRiskMessages,
      whatToLearn: learnMessage,
      whatToConsiderNext: nextMessage,
      aiProvider: 'DeterministicFallback',
      modelId: 'deterministic-v1',
      promptVersion: 'fallback-v1',
      latencyMs: 0,
    );
  }

  static String _extractDoneWell(CoachContext context) {
    final points = <String>[];

    final hasStopLossCode = context.disciplineReasonCodes
            .contains(DisciplineReasonCode.usedStopLoss) ||
        context.riskReasonCodes.contains(RiskReasonCode.stopLossPresent);
    if (hasStopLossCode || context.tradeContext.hasStopLoss) {
      points.add(
        'Automated stop-loss protection was configured for this simulated trade, establishing defined risk boundaries before order entry.',
      );
    }

    final hasDisciplinedSizing = context.disciplineReasonCodes
            .contains(DisciplineReasonCode.disciplinedPositionSize) ||
        context.riskReasonCodes.contains(RiskReasonCode.controlledPositionSize);
    if (hasDisciplinedSizing) {
      points.add(
        'Position size was kept within recommended allocation limits relative to total portfolio equity.',
      );
    }

    final hasControlledConcentration = context.disciplineReasonCodes
            .contains(DisciplineReasonCode.controlledConcentration) ||
        context.riskReasonCodes.contains(RiskReasonCode.balancedConcentration);
    if (hasControlledConcentration) {
      points.add(
        'Portfolio allocation remains balanced without excessive single-asset concentration.',
      );
    }

    if (context.disciplineReasonCodes
        .contains(DisciplineReasonCode.controlledTradingFrequency)) {
      points.add(
        'Trading frequency remains within deliberate 24-hour limits, preventing impulsive execution.',
      );
    }

    if (context.riskReasonCodes.contains(RiskReasonCode.normalVolatility)) {
      points.add(
        'Simulated asset volatility was within standard historical parameters at trade execution.',
      );
    }

    if (context.disciplineReasonCodes
        .contains(DisciplineReasonCode.goodRiskManagement)) {
      points.add(
        'Overall portfolio risk score was maintained within acceptable risk boundaries.',
      );
    }

    if (points.isEmpty) {
      return 'Completed simulated trade execution review. Continued focus on risk rules builds long-term process discipline.';
    }

    return points.join(' ');
  }

  static String _extractIncreasedRisk(CoachContext context) {
    final warnings = <String>[];

    final missingStopLoss = context.disciplineReasonCodes
            .contains(DisciplineReasonCode.missingStopLoss) ||
        context.riskReasonCodes.contains(RiskReasonCode.noStopLoss) ||
        !context.tradeContext.hasStopLoss;
    if (missingStopLoss) {
      warnings.add(
        'Trade executed without stop-loss protection, leaving capital exposed to unmanaged downside price swings.',
      );
    }

    final excessiveSizing = context.disciplineReasonCodes
            .contains(DisciplineReasonCode.excessivePositionSize) ||
        context.riskReasonCodes.contains(RiskReasonCode.largePositionSize);
    if (excessiveSizing) {
      warnings.add(
        'Position size allocation exceeds recommended risk limits relative to portfolio equity.',
      );
    }

    final highConcentration = context.disciplineReasonCodes
            .contains(DisciplineReasonCode.highConcentration) ||
        context.riskReasonCodes.contains(RiskReasonCode.highConcentration);
    if (highConcentration) {
      warnings.add(
        'High portfolio concentration (> 50% equity in one asset) increases vulnerability to single-asset volatility.',
      );
    }

    if (context.disciplineReasonCodes
        .contains(DisciplineReasonCode.highTradingFrequency)) {
      warnings.add(
        'Elevated 24-hour trading frequency (> 5 trades) indicates potential over-trading or impulsive entry.',
      );
    }

    if (context.disciplineReasonCodes
        .contains(DisciplineReasonCode.poorRiskManagement)) {
      warnings.add(
        'Overall portfolio risk score is currently elevated (> 60), requiring risk reduction.',
      );
    }

    if (context.riskReasonCodes.contains(RiskReasonCode.elevatedVolatility)) {
      warnings.add(
        'Selected cryptocurrency displays elevated 24-hour price volatility (> 5.0%), magnifying potential price swings.',
      );
    }

    if (warnings.isEmpty) {
      return 'No critical risk warnings detected for this simulated trade. Maintain your disciplined execution rules.';
    }

    return warnings.join(' ');
  }

  static String _buildEducationalSummary(CoachContext context) {
    final riskLevelName = context.riskScore.level.name.toUpperCase();
    final riskVal = context.riskScore.score;
    final discVal = context.disciplineScore.score;

    final buffer = StringBuffer(
      'Portfolio Risk: $riskLevelName ($riskVal/100). Trading Discipline Score: $discVal/100. ',
    );

    switch (context.riskScore.level) {
      case RiskLevel.low:
        buffer.write(
          'Your portfolio is operating under controlled risk conditions. Process quality is sustained by setting clear downside risk limits and maintaining disciplined position sizing before order execution.',
        );
      case RiskLevel.moderate:
        buffer.write(
          'Your portfolio is operating under moderate risk conditions. Focus on monitoring asset concentration and ensuring position sizes do not over-allocate capital to high-volatility movements.',
        );
      case RiskLevel.high:
        buffer.write(
          'Your portfolio risk exposure is elevated. Prioritize capital preservation by enforcing automated stop-loss limits and avoiding single-asset concentration.',
        );
      case RiskLevel.extreme:
        buffer.write(
          'Your portfolio is at extreme risk. High exposure threatens capital preservation. Focus on risk reduction over position expansion.',
        );
    }

    return buffer.toString();
  }

  static String _buildNextSteps(CoachContext context) {
    final missingStopLoss = context.disciplineReasonCodes
            .contains(DisciplineReasonCode.missingStopLoss) ||
        context.riskReasonCodes.contains(RiskReasonCode.noStopLoss) ||
        !context.tradeContext.hasStopLoss;
    final excessiveSizing = context.disciplineReasonCodes
            .contains(DisciplineReasonCode.excessivePositionSize) ||
        context.riskReasonCodes.contains(RiskReasonCode.largePositionSize);
    final highConcentration = context.disciplineReasonCodes
            .contains(DisciplineReasonCode.highConcentration) ||
        context.riskReasonCodes.contains(RiskReasonCode.highConcentration);
    final highFrequency = context.disciplineReasonCodes
        .contains(DisciplineReasonCode.highTradingFrequency);

    final recommendations = <String>[];

    if (missingStopLoss) {
      recommendations.add(
        '1. Define your maximum acceptable loss percentage and set a stop-loss order before entering your next trade.',
      );
    }

    if (excessiveSizing) {
      recommendations.add(
        '${recommendations.length + 1}. Scale back single-trade allocation to 10% or less of overall portfolio equity.',
      );
    }

    if (highConcentration) {
      recommendations.add(
        '${recommendations.length + 1}. Consider spreading simulated allocations across multiple supported crypto assets (BTC, ETH, SOL).',
      );
    }

    if (highFrequency) {
      recommendations.add(
        '${recommendations.length + 1}. Review your trade setups carefully and slow down execution pace to avoid over-trading.',
      );
    }

    if (recommendations.isEmpty) {
      return '1. Continue executing trades with predefined stop-loss orders. 2. Monitor overall portfolio risk gauges before placing new market orders.';
    }

    return recommendations.join(' ');
  }
}
