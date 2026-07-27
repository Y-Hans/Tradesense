import 'package:cryptoedu/features/coach/domain/coach_context_builder.dart';
import 'package:cryptoedu/features/intelligence/domain/reason_code.dart';
import 'package:cryptoedu/shared/models/discipline_score.dart';
import 'package:cryptoedu/shared/models/holding.dart';
import 'package:cryptoedu/shared/models/portfolio.dart';
import 'package:cryptoedu/shared/models/risk_score.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoachContext & CoachContextBuilder Unit Tests', () {
    const sampleRiskScore = RiskScore(
      score: 25,
      level: RiskLevel.low,
      concentrationScore: 10.0,
      sizingScore: 15.0,
      volatilityScore: 20.0,
      stopLossScore: 0.0,
      explanations: ['Low overall risk profile'],
    );

    const sampleDisciplineScore = DisciplineScore(
      score: 95,
      riskMgmtScore: 100.0,
      positionSizingScore: 100.0,
      stopLossDisciplineScore: 100.0,
      concentrationScore: 100.0,
      frequencyScore: 100.0,
      breakdownNotes: ['Disciplined execution'],
    );

    const riskCodes = [
      RiskReasonCode.balancedConcentration,
      RiskReasonCode.controlledPositionSize,
      RiskReasonCode.normalVolatility,
      RiskReasonCode.stopLossPresent,
    ];

    const disciplineCodes = [
      DisciplineReasonCode.goodRiskManagement,
      DisciplineReasonCode.disciplinedPositionSize,
      DisciplineReasonCode.usedStopLoss,
      DisciplineReasonCode.controlledConcentration,
      DisciplineReasonCode.controlledTradingFrequency,
    ];

    test(
        'CoachContext retains authoritative RiskScore and DisciplineScore unchanged',
        () {
      final context = CoachContextBuilder.build(
        symbol: 'BTC',
        side: TradeSide.buy,
        quantity: 0.05,
        executionPriceInr: 5000000.0,
        totalTradeValueInr: 250000.0,
        hasStopLoss: true,
        stopLossPriceInr: 4800000.0,
        tradeId: 'trade-101',
        totalEquityInr: 1000000.0,
        virtualCashBalanceInr: 750000.0,
        riskScore: sampleRiskScore,
        disciplineScore: sampleDisciplineScore,
        riskReasonCodes: riskCodes,
        disciplineReasonCodes: disciplineCodes,
      );

      expect(context.riskScore.score, equals(25));
      expect(context.riskScore.level, equals(RiskLevel.low));
      expect(context.disciplineScore.score, equals(95));
      expect(context.riskScore, equals(sampleRiskScore));
      expect(context.disciplineScore, equals(sampleDisciplineScore));
    });

    test('CoachContext preserves typed machine-readable reason codes', () {
      final context = CoachContextBuilder.build(
        symbol: 'ETH',
        side: TradeSide.buy,
        quantity: 1.0,
        executionPriceInr: 250000.0,
        totalTradeValueInr: 250000.0,
        hasStopLoss: true,
        totalEquityInr: 1000000.0,
        virtualCashBalanceInr: 750000.0,
        riskScore: sampleRiskScore,
        disciplineScore: sampleDisciplineScore,
        riskReasonCodes: riskCodes,
        disciplineReasonCodes: disciplineCodes,
      );

      expect(context.riskReasonCodes, equals(riskCodes));
      expect(context.disciplineReasonCodes, equals(disciplineCodes));
      expect(context.riskReasonCodes.first, isA<RiskReasonCode>());
      expect(context.disciplineReasonCodes.first, isA<DisciplineReasonCode>());
    });

    test('CoachContext maps trade and portfolio facts correctly', () {
      final context = CoachContextBuilder.build(
        symbol: 'SOL',
        side: TradeSide.sell,
        quantity: 10.0,
        executionPriceInr: 15000.0,
        totalTradeValueInr: 150000.0,
        hasStopLoss: false,
        tradeId: 'trade-303',
        totalEquityInr: 500000.0,
        virtualCashBalanceInr: 350000.0,
        riskScore: sampleRiskScore,
        disciplineScore: sampleDisciplineScore,
        riskReasonCodes: riskCodes,
        disciplineReasonCodes: disciplineCodes,
      );

      expect(context.tradeContext.symbol, equals('SOL'));
      expect(context.tradeContext.side, equals(TradeSide.sell));
      expect(context.tradeContext.quantity, equals(10.0));
      expect(context.tradeContext.executionPriceInr, equals(15000.0));
      expect(context.tradeContext.totalTradeValueInr, equals(150000.0));
      expect(context.tradeContext.hasStopLoss, isFalse);
      expect(context.tradeContext.tradeId, equals('trade-303'));
      expect(context.portfolioContext.totalEquityInr, equals(500000.0));
      expect(context.portfolioContext.virtualCashBalanceInr, equals(350000.0));
    });

    test(
        'CoachContextBuilder.fromTradeAndPortfolio maps trade and portfolio instances cleanly',
        () {
      const wallet = VirtualWallet(
        balanceInr: 80000.0,
        lockedInr: 0.0,
        initialBalanceInr: 100000.0,
      );
      const holding = Holding(
        id: 'h-1',
        userId: 'u-1',
        symbol: 'BTC',
        quantity: 0.01,
        averageEntryPriceInr: 4000000.0,
        currentPriceInr: 5000000.0,
      );
      const portfolio = Portfolio(
        wallet: wallet,
        holdings: [holding],
        totalRealisedPnlInr: 5000.0,
      );
      final trade = Trade(
        id: 'tr-001',
        userId: 'u-1',
        symbol: 'BTC',
        side: TradeSide.buy,
        type: OrderType.stopLoss,
        quantity: 0.01,
        executionPriceInr: 5000000.0,
        totalAmountInr: 50000.0,
        stopLossPriceInr: 4800000.0,
        timestamp: DateTime(2026, 7, 27),
        disciplineScoreAtTrade: 90,
        riskScoreAtTrade: 20,
      );

      final context = CoachContextBuilder.fromTradeAndPortfolio(
        trade: trade,
        portfolio: portfolio,
        riskScore: sampleRiskScore,
        disciplineScore: sampleDisciplineScore,
        riskReasonCodes: riskCodes,
        disciplineReasonCodes: disciplineCodes,
      );

      expect(context.tradeContext.symbol, equals('BTC'));
      expect(context.tradeContext.side, equals(TradeSide.buy));
      expect(context.tradeContext.hasStopLoss, isTrue);
      expect(context.tradeContext.stopLossPriceInr, equals(4800000.0));
      expect(context.portfolioContext.totalEquityInr, equals(130000.0));
      expect(context.portfolioContext.virtualCashBalanceInr, equals(80000.0));
    });

    test('CoachContextBuilder is completely deterministic for identical inputs',
        () {
      final ctx1 = CoachContextBuilder.build(
        symbol: 'XRP',
        side: TradeSide.buy,
        quantity: 500.0,
        executionPriceInr: 100.0,
        totalTradeValueInr: 50000.0,
        hasStopLoss: true,
        totalEquityInr: 200000.0,
        virtualCashBalanceInr: 150000.0,
        riskScore: sampleRiskScore,
        disciplineScore: sampleDisciplineScore,
        riskReasonCodes: riskCodes,
        disciplineReasonCodes: disciplineCodes,
      );

      final ctx2 = CoachContextBuilder.build(
        symbol: 'XRP',
        side: TradeSide.buy,
        quantity: 500.0,
        executionPriceInr: 100.0,
        totalTradeValueInr: 50000.0,
        hasStopLoss: true,
        totalEquityInr: 200000.0,
        virtualCashBalanceInr: 150000.0,
        riskScore: sampleRiskScore,
        disciplineScore: sampleDisciplineScore,
        riskReasonCodes: riskCodes,
        disciplineReasonCodes: disciplineCodes,
      );

      expect(ctx1, equals(ctx2));
      expect(ctx1.hashCode, equals(ctx2.hashCode));
    });

    test('CoachContext does not require OpenRouter or model configuration', () {
      final context = CoachContextBuilder.build(
        symbol: 'BNB',
        side: TradeSide.buy,
        quantity: 2.0,
        executionPriceInr: 40000.0,
        totalTradeValueInr: 80000.0,
        hasStopLoss: false,
        totalEquityInr: 100000.0,
        virtualCashBalanceInr: 20000.0,
        riskScore: sampleRiskScore,
        disciplineScore: sampleDisciplineScore,
        riskReasonCodes: riskCodes,
        disciplineReasonCodes: disciplineCodes,
      );

      expect(context.toString(), contains('BNB'));
      expect(context.tradeContext.toString(), contains('BNB'));
      expect(context.portfolioContext.toString(), contains('100000'));
    });
  });
}
