import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/core/utils/risk_calculator.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:cryptoedu/shared/models/portfolio.dart';
import 'package:cryptoedu/shared/models/holding.dart';
import 'package:cryptoedu/shared/models/risk_score.dart';

void main() {
  group('RiskCalculator Unit Tests', () {
    test('Balanced portfolio with stop-loss returns LOW risk level', () {
      final portfolio = Portfolio(
        wallet: VirtualWallet.initial(), // ₹100,000 cash
        holdings: const [],
        totalRealisedPnlInr: 0.0,
      );

      final risk = RiskCalculator.compute(
        portfolio: portfolio,
        proposedTradeSizeInr: 5000.0, // 5% of equity
        hasStopLoss: true,
        assetVolatility: 2.0, // Low volatility
      );

      expect(risk.score, lessThanOrEqualTo(30));
      expect(risk.level, RiskLevel.low);
      expect(risk.stopLossScore, 0.0);
      expect(risk.explanations,
          contains('Well-balanced position size and risk control.'));
    });

    test('Concentrated portfolio receives concentration penalty', () {
      const portfolio = Portfolio(
        wallet: VirtualWallet(balanceInr: 20000.0, lockedInr: 0.0),
        holdings: [
          Holding(
            id: 'h1',
            userId: 'user1',
            symbol: 'BTC',
            quantity: 1.0,
            averageEntryPriceInr: 80000.0,
            currentPriceInr: 80000.0,
          ),
        ],
        totalRealisedPnlInr: 0.0,
      ); // Total equity: ₹100,000, concentration = 80%

      final risk = RiskCalculator.compute(
        portfolio: portfolio,
        proposedTradeSizeInr: 10000.0,
        hasStopLoss: true,
        assetVolatility: 3.0,
      );

      expect(risk.concentrationScore, closeTo(80.0, 0.1));
      expect(
        risk.explanations
            .any((e) => e.contains('High portfolio concentration')),
        isTrue,
      );
    });

    test('Oversized trade position (> 25% equity) receives sizing penalty', () {
      final portfolio = Portfolio(
        wallet: VirtualWallet.initial(),
        holdings: const [],
        totalRealisedPnlInr: 0.0,
      );

      final risk = RiskCalculator.compute(
        portfolio: portfolio,
        proposedTradeSizeInr: 4000000.0, // 40% of equity (10,000,000 balance)
        hasStopLoss: true,
        assetVolatility: 2.0,
      );

      expect(risk.sizingScore, closeTo(80.0, 0.1)); // 40% * 2 = 80
      expect(
        risk.explanations.any((e) => e.contains('Large position size')),
        isTrue,
      );
    });

    test('Omitted stop-loss penalizes stop-loss component with 100 raw score',
        () {
      final portfolio = Portfolio(
        wallet: VirtualWallet.initial(),
        holdings: const [],
        totalRealisedPnlInr: 0.0,
      );

      final riskWithStopLoss = RiskCalculator.compute(
        portfolio: portfolio,
        proposedTradeSizeInr: 10000.0,
        hasStopLoss: true,
        assetVolatility: 3.0,
      );

      final riskWithoutStopLoss = RiskCalculator.compute(
        portfolio: portfolio,
        proposedTradeSizeInr: 10000.0,
        hasStopLoss: false,
        assetVolatility: 3.0,
      );

      expect(riskWithStopLoss.stopLossScore, 0.0);
      expect(riskWithoutStopLoss.stopLossScore, 100.0);
      expect(riskWithoutStopLoss.score, greaterThan(riskWithStopLoss.score));
      expect(
        riskWithoutStopLoss.explanations,
        contains('No stop-loss protection set on this trade.'),
      );
    });

    test('High market volatility (> 5.0%) triggers volatility explanation', () {
      final portfolio = Portfolio(
        wallet: VirtualWallet.initial(),
        holdings: const [],
        totalRealisedPnlInr: 0.0,
      );

      final risk = RiskCalculator.compute(
        portfolio: portfolio,
        proposedTradeSizeInr: 10000.0,
        hasStopLoss: true,
        assetVolatility: 8.5,
      );

      expect(risk.volatilityScore, 85.0);
      expect(
        risk.explanations.any((e) => e.contains('Elevated market volatility')),
        isTrue,
      );
    });

    test('RiskLevel classification boundaries match documented thresholds', () {
      expect(RiskScore.calculateLevel(0), RiskLevel.low);
      expect(RiskScore.calculateLevel(30), RiskLevel.low);
      expect(RiskScore.calculateLevel(31), RiskLevel.moderate);
      expect(RiskScore.calculateLevel(60), RiskLevel.moderate);
      expect(RiskScore.calculateLevel(61), RiskLevel.high);
      expect(RiskScore.calculateLevel(80), RiskLevel.high);
      expect(RiskScore.calculateLevel(81), RiskLevel.extreme);
      expect(RiskScore.calculateLevel(100), RiskLevel.extreme);
    });

    test('Upper boundary parameters produce EXTREME risk score', () {
      const portfolio = Portfolio(
        wallet: VirtualWallet(balanceInr: 0.0, lockedInr: 0.0),
        holdings: [
          Holding(
            id: 'h2',
            userId: 'user1',
            symbol: 'SOL',
            quantity: 100.0,
            averageEntryPriceInr: 1000.0,
            currentPriceInr: 1000.0,
          ),
        ],
        totalRealisedPnlInr: 0.0,
      ); // 100% concentration

      final risk = RiskCalculator.compute(
        portfolio: portfolio,
        proposedTradeSizeInr:
            60000.0, // 60% of equity -> sizing score capped at 100
        hasStopLoss: false, // 100 stop loss score
        assetVolatility: 12.0, // Volatility raw capped at 100
      );

      expect(risk.score, 100);
      expect(risk.level, RiskLevel.extreme);
    });
  });
}
