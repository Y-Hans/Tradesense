import 'package:flutter/foundation.dart';
import '../../../shared/models/discipline_score.dart';
import '../../../shared/models/risk_score.dart';
import '../../../shared/models/trade.dart';
import '../../intelligence/domain/reason_code.dart';

/// Structured, provider-neutral domain representation of trade facts required for AI Coaching.
@immutable
class CoachTradeContext {
  final String symbol;
  final TradeSide side;
  final double quantity;
  final double executionPriceInr;
  final double totalTradeValueInr;
  final bool hasStopLoss;
  final double? stopLossPriceInr;
  final String? tradeId;

  const CoachTradeContext({
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.executionPriceInr,
    required this.totalTradeValueInr,
    required this.hasStopLoss,
    this.stopLossPriceInr,
    this.tradeId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachTradeContext &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          side == other.side &&
          quantity == other.quantity &&
          executionPriceInr == other.executionPriceInr &&
          totalTradeValueInr == other.totalTradeValueInr &&
          hasStopLoss == other.hasStopLoss &&
          stopLossPriceInr == other.stopLossPriceInr &&
          tradeId == other.tradeId;

  @override
  int get hashCode =>
      symbol.hashCode ^
      side.hashCode ^
      quantity.hashCode ^
      executionPriceInr.hashCode ^
      totalTradeValueInr.hashCode ^
      hasStopLoss.hashCode ^
      stopLossPriceInr.hashCode ^
      tradeId.hashCode;

  @override
  String toString() =>
      'CoachTradeContext(symbol: $symbol, side: ${side.name}, totalValue: $totalTradeValueInr, stopLoss: $hasStopLoss)';
}

/// Structured, provider-neutral domain representation of portfolio facts required for AI Coaching.
@immutable
class CoachPortfolioContext {
  final double totalEquityInr;
  final double virtualCashBalanceInr;

  const CoachPortfolioContext({
    required this.totalEquityInr,
    required this.virtualCashBalanceInr,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachPortfolioContext &&
          runtimeType == other.runtimeType &&
          totalEquityInr == other.totalEquityInr &&
          virtualCashBalanceInr == other.virtualCashBalanceInr;

  @override
  int get hashCode => totalEquityInr.hashCode ^ virtualCashBalanceInr.hashCode;

  @override
  String toString() =>
      'CoachPortfolioContext(totalEquity: $totalEquityInr, cash: $virtualCashBalanceInr)';
}

/// Provider-independent domain representation of trusted facts required for educational coaching.
///
/// Contains NO OpenRouter prompt text, model-specific instructions, API keys, or UI markup.
@immutable
class CoachContext {
  final CoachTradeContext tradeContext;
  final CoachPortfolioContext portfolioContext;
  final RiskScore riskScore;
  final DisciplineScore disciplineScore;
  final List<RiskReasonCode> riskReasonCodes;
  final List<DisciplineReasonCode> disciplineReasonCodes;

  const CoachContext({
    required this.tradeContext,
    required this.portfolioContext,
    required this.riskScore,
    required this.disciplineScore,
    required this.riskReasonCodes,
    required this.disciplineReasonCodes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachContext &&
          runtimeType == other.runtimeType &&
          tradeContext == other.tradeContext &&
          portfolioContext == other.portfolioContext &&
          riskScore.score == other.riskScore.score &&
          riskScore.level == other.riskScore.level &&
          disciplineScore.score == other.disciplineScore.score &&
          listEquals(riskReasonCodes, other.riskReasonCodes) &&
          listEquals(disciplineReasonCodes, other.disciplineReasonCodes);

  @override
  int get hashCode =>
      tradeContext.hashCode ^
      portfolioContext.hashCode ^
      riskScore.score.hashCode ^
      disciplineScore.score.hashCode ^
      Object.hashAll(riskReasonCodes) ^
      Object.hashAll(disciplineReasonCodes);

  @override
  String toString() =>
      'CoachContext(symbol: ${tradeContext.symbol}, riskScore: ${riskScore.score}, disciplineScore: ${disciplineScore.score})';
}
