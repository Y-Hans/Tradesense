import 'package:flutter/foundation.dart';
import 'domain_event.dart';

/// Event published when portfolio risk evaluation completes.
@immutable
class RiskEvaluationCompleted extends DomainEvent {
  final int riskScore;
  final String riskLevel;
  final List<String> reasonCodes;
  final double proposedTradeSizeInr;
  final bool hasStopLoss;

  RiskEvaluationCompleted({
    required this.riskScore,
    required this.riskLevel,
    required this.reasonCodes,
    required this.proposedTradeSizeInr,
    required this.hasStopLoss,
    super.occurredAt,
  }) : super(eventType: 'RiskEvaluationCompleted');
}

/// Event published when trading discipline evaluation completes.
@immutable
class DisciplineEvaluationCompleted extends DomainEvent {
  final int disciplineScore;
  final List<String> reasonCodes;
  final double positionSizePercentage;
  final bool usedStopLoss;

  DisciplineEvaluationCompleted({
    required this.disciplineScore,
    required this.reasonCodes,
    required this.positionSizePercentage,
    required this.usedStopLoss,
    super.occurredAt,
  }) : super(eventType: 'DisciplineEvaluationCompleted');
}

/// Event published when an AI Coach session completes.
@immutable
class CoachSessionCompleted extends DomainEvent {
  final String tradeId;
  final String userId;
  final int riskScore;
  final int disciplineScore;
  final bool isFallback;
  final String providerName;

  CoachSessionCompleted({
    required this.tradeId,
    required this.userId,
    required this.riskScore,
    required this.disciplineScore,
    required this.isFallback,
    required this.providerName,
    super.occurredAt,
  }) : super(eventType: 'CoachSessionCompleted');
}

/// Event published when a trade execution completes.
@immutable
class TradeExecuted extends DomainEvent {
  final String tradeId;
  final String userId;
  final String symbol;
  final String side;
  final double quantity;
  final double executionPriceInr;
  final double totalAmountInr;
  final bool hasStopLoss;
  final double? stopLossPriceInr;

  TradeExecuted({
    required this.tradeId,
    required this.userId,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.executionPriceInr,
    required this.totalAmountInr,
    required this.hasStopLoss,
    this.stopLossPriceInr,
    super.occurredAt,
  }) : super(eventType: 'TradeExecuted');
}
