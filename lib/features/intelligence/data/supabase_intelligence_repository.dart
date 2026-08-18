import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../../../core/contracts/repository_contracts.dart';
import '../../../core/events/domain_event_publisher.dart';
import '../../../core/events/domain_events.dart';
import '../../../core/utils/risk_calculator.dart';
import '../../../core/utils/discipline_calculator.dart';
import '../../../shared/models/trade.dart';
import '../../../shared/models/portfolio.dart';
import '../../../shared/models/risk_score.dart';
import '../../../shared/models/discipline_score.dart';
import '../../../shared/models/coach_request.dart';

class SupabaseIntelligenceRepository implements IntelligenceRepository {
  final SupabaseClient _client;
  final DomainEventPublisher? _eventPublisher;

  SupabaseIntelligenceRepository({
    SupabaseClient? client,
    DomainEventPublisher? eventPublisher,
  })  : _client = client ?? Supabase.instance.client,
        _eventPublisher = eventPublisher;

  @override
  RiskScore calculateRiskScore({
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

    _eventPublisher?.publish(
      RiskEvaluationCompleted(
        riskScore: score.score,
        riskLevel: score.level.name,
        reasonCodes: score.explanations,
        proposedTradeSizeInr: proposedTradeSizeInr,
        hasStopLoss: hasStopLoss,
      ),
    );

    return score;
  }

  @override
  DisciplineScore calculateDisciplineScore({
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

    _eventPublisher?.publish(
      DisciplineEvaluationCompleted(
        disciplineScore: score.score,
        reasonCodes: score.breakdownNotes,
        positionSizePercentage: positionSizePercentage,
        usedStopLoss: usedStopLoss,
      ),
    );

    return score;
  }

  @override
  Future<TradeAnalysis> analyzeTrade(Trade trade, Portfolio portfolio) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final risk = calculateRiskScore(
      portfolio: portfolio,
      proposedTradeSizeInr: trade.totalAmountInr,
      hasStopLoss: trade.stopLossPriceInr != null,
      assetVolatility: 3.5,
    );

    final discipline = calculateDisciplineScore(
      currentRiskScore: risk,
      positionSizePercentage:
          (trade.totalAmountInr / portfolio.totalPortfolioValueInr) * 100.0,
      usedStopLoss: trade.stopLossPriceInr != null,
      portfolioConcentration: 25.0,
      tradeFrequency24h: 2,
    );

    final request = CoachRequest(
      userId: userId,
      tradeId: trade.id,
      tradeContext: trade.toJson(),
      portfolioContext: portfolio.toJson(),
      marketContext: const {}, // Assuming not strictly required for this payload, or fetch it
      riskScore: risk.score,
      disciplineScore: discipline.score,
    );

    // Call Supabase Edge Function to get AI analysis
    final response = await _client.functions.invoke(
      'analyze_trade',
      body: {
        'trade_id': request.tradeId,
        'trade_details': request.tradeContext,
        'discipline_score': request.disciplineScore,
        'risk_score': request.riskScore,
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to get coach feedback from Edge Function: \${response.status}');
    }

    final data = response.data as Map<String, dynamic>;

    final coachFeedback = CoachResponse(
      whatDoneWell: data['what_done_well'] as String? ?? 'Good position sizing.',
      whatIncreasedRisk: data['what_increased_risk'] as String? ?? 'No major risk factors.',
      whatToLearn: data['what_to_learn'] as String? ?? 'Keep practicing discipline.',
      whatToConsiderNext: data['what_to_consider_next'] as String? ?? 'Maintain your strategy.',
      aiProvider: data['ai_provider'] as String? ?? 'OpenRouter',
      modelId: data['model_id'] as String? ?? 'gpt-3.5-turbo',
      promptVersion: data['prompt_version'] as String? ?? '1.0',
      latencyMs: data['latency_ms'] as int? ?? 0,
    );

    final analysis = TradeAnalysis(
      tradeId: trade.id,
      disciplineScore: discipline,
      riskScore: risk,
      coachFeedback: coachFeedback,
      analyzedAt: DateTime.now(),
    );

    return analysis;
  }
}
