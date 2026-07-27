import 'package:flutter/foundation.dart';
import 'risk_score.dart';
import 'discipline_score.dart';

@immutable
class CoachRequest {
  final String userId;
  final String tradeId;
  final Map<String, dynamic> tradeContext;
  final Map<String, dynamic> portfolioContext;
  final Map<String, dynamic> marketContext;
  final int riskScore;
  final int disciplineScore;

  const CoachRequest({
    required this.userId,
    required this.tradeId,
    required this.tradeContext,
    required this.portfolioContext,
    required this.marketContext,
    required this.riskScore,
    required this.disciplineScore,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'trade_id': tradeId,
        'trade_context': tradeContext,
        'portfolio_context': portfolioContext,
        'market_context': marketContext,
        'risk_score': riskScore,
        'discipline_score': disciplineScore,
      };

  factory CoachRequest.fromJson(Map<String, dynamic> json) => CoachRequest(
        userId: json['user_id'] as String,
        tradeId: json['trade_id'] as String,
        tradeContext: Map<String, dynamic>.from(json['trade_context'] as Map),
        portfolioContext: Map<String, dynamic>.from(json['portfolio_context'] as Map),
        marketContext: Map<String, dynamic>.from(json['market_context'] as Map),
        riskScore: (json['risk_score'] as num).toInt(),
        disciplineScore: (json['discipline_score'] as num).toInt(),
      );
}

@immutable
class CoachResponse {
  final String whatDoneWell;
  final String whatIncreasedRisk;
  final String whatToLearn;
  final String whatToConsiderNext;
  final String aiProvider;
  final String modelId;
  final String promptVersion;
  final int latencyMs;

  const CoachResponse({
    required this.whatDoneWell,
    required this.whatIncreasedRisk,
    required this.whatToLearn,
    required this.whatToConsiderNext,
    required this.aiProvider,
    required this.modelId,
    required this.promptVersion,
    required this.latencyMs,
  });

  Map<String, dynamic> toJson() => {
        'what_done_well': whatDoneWell,
        'what_increased_risk': whatIncreasedRisk,
        'what_to_learn': whatToLearn,
        'what_to_consider_next': whatToConsiderNext,
        'ai_provider': aiProvider,
        'model_id': modelId,
        'prompt_version': promptVersion,
        'latency_ms': latencyMs,
      };

  factory CoachResponse.fromJson(Map<String, dynamic> json) => CoachResponse(
        whatDoneWell: json['what_done_well'] as String,
        whatIncreasedRisk: json['what_increased_risk'] as String,
        whatToLearn: json['what_to_learn'] as String,
        whatToConsiderNext: json['what_to_consider_next'] as String,
        aiProvider: json['ai_provider'] as String? ?? 'OpenRouter',
        modelId: json['model_id'] as String? ?? 'anthropic/claude-3.5-sonnet',
        promptVersion: json['prompt_version'] as String? ?? 'v1.0.0',
        latencyMs: (json['latency_ms'] as num?)?.toInt() ?? 250,
      );
}

@immutable
class TradeAnalysis {
  final String tradeId;
  final DisciplineScore disciplineScore;
  final RiskScore riskScore;
  final CoachResponse coachFeedback;
  final DateTime analyzedAt;

  const TradeAnalysis({
    required this.tradeId,
    required this.disciplineScore,
    required this.riskScore,
    required this.coachFeedback,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() => {
        'trade_id': tradeId,
        'discipline_score': disciplineScore.toJson(),
        'risk_score': riskScore.toJson(),
        'coach_feedback': coachFeedback.toJson(),
        'analyzed_at': analyzedAt.toIso8601String(),
      };

  factory TradeAnalysis.fromJson(Map<String, dynamic> json) => TradeAnalysis(
        tradeId: json['trade_id'] as String,
        disciplineScore: DisciplineScore.fromJson(json['discipline_score'] as Map<String, dynamic>),
        riskScore: RiskScore.fromJson(json['risk_score'] as Map<String, dynamic>),
        coachFeedback: CoachResponse.fromJson(json['coach_feedback'] as Map<String, dynamic>),
        analyzedAt: DateTime.parse(json['analyzed_at'] as String),
      );
}
