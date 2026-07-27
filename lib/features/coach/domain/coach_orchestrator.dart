import 'dart:async';

import '../../../core/contracts/provider_contracts.dart';
import '../../../shared/models/coach_request.dart';
import 'coach_context.dart';
import 'fallback_coach.dart';

/// Provider-independent AI Coach orchestrator.
///
/// Accepts trusted [CoachContext], attempts generative coaching through the
/// abstract [AIProvider] contract, and automatically returns deterministic
/// [FallbackCoach] output when AI is unavailable, disabled, malformed, or encounters an exception.
///
/// Does NOT:
/// - calculate Risk Score, Discipline Score, or P&L,
/// - call OpenRouter directly or know model IDs / API keys,
/// - access UI, execute trades, or modify portfolio state,
/// - expose infrastructure error details to the educational coaching flow.
class CoachOrchestrator {
  final AIProvider _aiProvider;
  final bool aiEnabled;

  /// Creates a [CoachOrchestrator] with the given abstract [AIProvider].
  ///
  /// Set [aiEnabled] to `false` to skip the provider entirely and return
  /// deterministic fallback coaching immediately. This allows consuming
  /// `FeatureFlags.aiCoachEnabled` without inventing infrastructure configuration.
  const CoachOrchestrator({
    required AIProvider aiProvider,
    this.aiEnabled = true,
  }) : _aiProvider = aiProvider;

  /// Produces educational coaching for the given [CoachContext].
  ///
  /// Returns valid AI provider output on success, or deterministic
  /// [FallbackCoach] output on expected provider/runtime failure paths.
  Future<CoachResponse> getCoachResponse(
    CoachContext context, {
    required String userId,
  }) async {
    // Feature-disabled: skip provider entirely, return deterministic fallback.
    if (!aiEnabled) {
      return FallbackCoach.analyze(context);
    }

    try {
      final request = _buildRequest(context, userId);
      final response = await _aiProvider.generateCoachFeedback(request);

      // Validate structural invariants established by the CoachResponse contract.
      if (_isResponseMalformed(response)) {
        return FallbackCoach.analyze(context);
      }

      return response;
    } on Exception {
      // Expected provider/runtime failure (network, timeout, server error) -> return fallback.
      return FallbackCoach.analyze(context);
    }
  }

  /// Maps [CoachContext] to [CoachRequest] using structured data.
  ///
  /// Reason codes are serialized as stable machine-readable string codes
  /// within the context maps — NOT converted to prose. The server-side
  /// Edge Function constructs prompts from this structured data.
  CoachRequest _buildRequest(CoachContext context, String userId) {
    return CoachRequest(
      userId: userId,
      tradeId: context.tradeContext.tradeId ?? '',
      tradeContext: <String, dynamic>{
        'symbol': context.tradeContext.symbol,
        'side': context.tradeContext.side.name,
        'quantity': context.tradeContext.quantity,
        'execution_price_inr': context.tradeContext.executionPriceInr,
        'total_trade_value_inr': context.tradeContext.totalTradeValueInr,
        'has_stop_loss': context.tradeContext.hasStopLoss,
        if (context.tradeContext.stopLossPriceInr != null)
          'stop_loss_price_inr': context.tradeContext.stopLossPriceInr,
      },
      portfolioContext: <String, dynamic>{
        'total_equity_inr': context.portfolioContext.totalEquityInr,
        'virtual_cash_balance_inr':
            context.portfolioContext.virtualCashBalanceInr,
      },
      marketContext: <String, dynamic>{
        'risk_reason_codes':
            context.riskReasonCodes.map((r) => r.code).toList(),
        'discipline_reason_codes':
            context.disciplineReasonCodes.map((d) => d.code).toList(),
      },
      riskScore: context.riskScore.score,
      disciplineScore: context.disciplineScore.score,
    );
  }

  /// Checks whether a provider response violates structural invariants of [CoachResponse].
  ///
  /// Validates established contract requirements (non-empty required feedback fields).
  /// Does NOT evaluate arbitrary AI wording or content quality.
  bool _isResponseMalformed(CoachResponse response) {
    return response.whatDoneWell.trim().isEmpty ||
        response.whatIncreasedRisk.trim().isEmpty ||
        response.whatToLearn.trim().isEmpty ||
        response.whatToConsiderNext.trim().isEmpty;
  }
}
