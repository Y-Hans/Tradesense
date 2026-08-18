import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryptoedu/app/theme/app_theme.dart';
import 'package:cryptoedu/core/providers/app_providers.dart';
import 'package:cryptoedu/core/contracts/repository_contracts.dart';
import 'package:cryptoedu/features/coach/presentation/coach_result_screen.dart';
import 'package:cryptoedu/shared/models/trade.dart';
import 'package:cryptoedu/shared/models/portfolio.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:cryptoedu/shared/models/risk_score.dart';
import 'package:cryptoedu/shared/models/discipline_score.dart';
import 'package:cryptoedu/shared/models/coach_request.dart';

class FakeTradingRepository implements TradingRepository {
  final List<Trade> _trades;

  FakeTradingRepository(this._trades);

  @override
  Future<Trade> executeMarketBuy({
    required String symbol,
    required double quantity,
    required double executionPriceInr,
    double? stopLossPriceInr,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Trade> executeMarketSell({
    required String symbol,
    required double quantity,
    required double executionPriceInr,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Trade>> getTradeHistory() async {
    return _trades;
  }
}

class FakeIntelligenceRepository implements IntelligenceRepository {
  @override
  RiskScore calculateRiskScore({required Portfolio portfolio, required double proposedTradeSizeInr, required bool hasStopLoss, required double assetVolatility}) {
    return const RiskScore(score: 35, level: RiskLevel.low, explanations: [], concentrationScore: 10, sizingScore: 10, stopLossScore: 10, volatilityScore: 5);
  }

  @override
  DisciplineScore calculateDisciplineScore({required RiskScore currentRiskScore, required double positionSizePercentage, required bool usedStopLoss, required double portfolioConcentration, required int tradeFrequency24h}) {
    return const DisciplineScore(score: 85, breakdownNotes: [], concentrationScore: 15, frequencyScore: 15, positionSizingScore: 20, riskMgmtScore: 15, stopLossDisciplineScore: 20);
  }

  @override
  Future<TradeAnalysis> analyzeTrade(Trade trade, Portfolio portfolio) async {
    return TradeAnalysis(
      tradeId: trade.id,
      disciplineScore: const DisciplineScore(score: 85, breakdownNotes: [], concentrationScore: 15, frequencyScore: 15, positionSizingScore: 20, riskMgmtScore: 15, stopLossDisciplineScore: 20),
      riskScore: const RiskScore(score: 35, level: RiskLevel.low, explanations: [], concentrationScore: 10, sizingScore: 10, stopLossScore: 10, volatilityScore: 5),
      coachFeedback: const CoachResponse(
        whatDoneWell: 'Good',
        whatIncreasedRisk: 'None',
        whatToLearn: 'Nothing',
        whatToConsiderNext: 'Keep going',
        aiProvider: 'Mock',
        modelId: 'Mock',
        promptVersion: '1',
        latencyMs: 10,
      ),
      analyzedAt: DateTime.now(),
    );
  }
}

void main() {
  final testTrade = Trade(
    id: 'test_trade_123',
    userId: 'user_1',
    symbol: 'BTC',
    side: TradeSide.buy,
    type: OrderType.market,
    quantity: 0.1,
    executionPriceInr: 5850000.0,
    totalAmountInr: 585000.0,
    stopLossPriceInr: 5557500.0,
    timestamp: DateTime.now(),
    disciplineScoreAtTrade: 85,
    riskScoreAtTrade: 35,
  );

  Widget buildTestApp(String tradeId, List<Trade> history) {
    return ProviderScope(
      overrides: [
        tradingRepositoryProvider.overrideWithValue(FakeTradingRepository(history)),
        intelligenceRepositoryProvider.overrideWithValue(FakeIntelligenceRepository()),
        portfolioProvider.overrideWith((ref) => Future.value(
          const Portfolio(
            wallet: VirtualWallet(balanceInr: 100000, lockedInr: 0, initialBalanceInr: 100000),
            holdings: [],
            totalRealisedPnlInr: 0,
          )
        )),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: CoachResultScreen(tradeId: tradeId),
      ),
    );
  }

  testWidgets('CoachResultScreen renders trade details when found', (tester) async {
    await tester.pumpWidget(buildTestApp('test_trade_123', [testTrade]));
    await tester.pumpAndSettle();

    expect(find.text('AI Coach Trade Explanation'), findsOneWidget);
    expect(find.text('Discipline Score'), findsOneWidget);
    expect(find.text('Risk Score'), findsOneWidget);
    expect(find.text('AI Coach Analysis'), findsOneWidget);
  });

  testWidgets('CoachResultScreen renders Trade Not Found when tradeId does not exist', (tester) async {
    await tester.pumpWidget(buildTestApp('invalid_id', [testTrade]));
    await tester.pumpAndSettle();

    expect(find.text('AI Coach Trade Explanation'), findsOneWidget);
    expect(find.text('Trade Not Found'), findsOneWidget);
    expect(find.text('AI Coach Analysis'), findsNothing);
  });
}
