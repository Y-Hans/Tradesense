import '../../../shared/models/discipline_score.dart';
import '../../../shared/models/portfolio.dart';
import '../../../shared/models/risk_score.dart';
import '../../../shared/models/trade.dart';
import '../../intelligence/domain/reason_code.dart';
import 'coach_context.dart';

/// Pure deterministic builder assembling [CoachContext] from trusted pre-calculated facts.
///
/// Does NOT call OpenRouter, Supabase, market APIs, Riverpod, or prompt generators.
/// Does NOT recalculate Risk Score, Discipline Score, or trading P&L.
class CoachContextBuilder {
  /// Builds a deterministic [CoachContext] from individual trade/portfolio facts and intelligence outputs.
  static CoachContext build({
    required String symbol,
    required TradeSide side,
    required double quantity,
    required double executionPriceInr,
    required double totalTradeValueInr,
    required bool hasStopLoss,
    double? stopLossPriceInr,
    String? tradeId,
    required double totalEquityInr,
    required double virtualCashBalanceInr,
    required RiskScore riskScore,
    required DisciplineScore disciplineScore,
    required List<RiskReasonCode> riskReasonCodes,
    required List<DisciplineReasonCode> disciplineReasonCodes,
  }) {
    return CoachContext(
      tradeContext: CoachTradeContext(
        symbol: symbol,
        side: side,
        quantity: quantity,
        executionPriceInr: executionPriceInr,
        totalTradeValueInr: totalTradeValueInr,
        hasStopLoss: hasStopLoss,
        stopLossPriceInr: stopLossPriceInr,
        tradeId: tradeId,
      ),
      portfolioContext: CoachPortfolioContext(
        totalEquityInr: totalEquityInr,
        virtualCashBalanceInr: virtualCashBalanceInr,
      ),
      riskScore: riskScore,
      disciplineScore: disciplineScore,
      riskReasonCodes: List.unmodifiable(riskReasonCodes),
      disciplineReasonCodes: List.unmodifiable(disciplineReasonCodes),
    );
  }

  /// Convenience builder assembling [CoachContext] from [Trade], [Portfolio], and intelligence outputs.
  static CoachContext fromTradeAndPortfolio({
    required Trade trade,
    required Portfolio portfolio,
    required RiskScore riskScore,
    required DisciplineScore disciplineScore,
    required List<RiskReasonCode> riskReasonCodes,
    required List<DisciplineReasonCode> disciplineReasonCodes,
  }) {
    final hasStopLoss =
        trade.stopLossPriceInr != null || trade.type == OrderType.stopLoss;

    return build(
      symbol: trade.symbol,
      side: trade.side,
      quantity: trade.quantity,
      executionPriceInr: trade.executionPriceInr,
      totalTradeValueInr: trade.totalAmountInr,
      hasStopLoss: hasStopLoss,
      stopLossPriceInr: trade.stopLossPriceInr,
      tradeId: trade.id,
      totalEquityInr: portfolio.totalPortfolioValueInr,
      virtualCashBalanceInr: portfolio.wallet.balanceInr,
      riskScore: riskScore,
      disciplineScore: disciplineScore,
      riskReasonCodes: riskReasonCodes,
      disciplineReasonCodes: disciplineReasonCodes,
    );
  }
}
