import 'package:cryptoedu/core/utils/financial_math.dart';
import 'package:cryptoedu/shared/models/portfolio.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Virtual wallet initialization', () {
    test('new wallet starts at exactly one crore INR', () {
      final wallet = VirtualWallet.initial();

      expect(VirtualWallet.startingBalanceInr, 10000000.0);
      expect(FinancialMath.inrToPaise(wallet.balanceInr), 1000000000);
      expect(FinancialMath.inrToPaise(wallet.initialBalanceInr), 1000000000);
      expect(wallet.balanceInr, VirtualWallet.startingBalanceInr);
      expect(wallet.initialBalanceInr, VirtualWallet.startingBalanceInr);
      expect(wallet.lockedInr, 0.0);
      expect(wallet.availableBalanceInr, VirtualWallet.startingBalanceInr);
    });

    test('initial factory is idempotent', () {
      final firstWallet = VirtualWallet.initial();
      final secondWallet = VirtualWallet.initial();

      expect(secondWallet.toJson(), firstWallet.toJson());
    });

    test('existing financial state is not reset', () {
      const existingInitialBalanceInr = 100000.0;
      final wallet = VirtualWallet.fromJson(const {
        'balance_inr': 87500.25,
        'locked_inr': 2500.75,
        'initial_balance_inr': existingInitialBalanceInr,
      });

      final updatedWallet = wallet.copyWith(lockedInr: 1000.0);

      expect(wallet.balanceInr, 87500.25);
      expect(wallet.lockedInr, 2500.75);
      expect(wallet.initialBalanceInr, existingInitialBalanceInr);
      expect(updatedWallet.balanceInr, wallet.balanceInr);
      expect(updatedWallet.initialBalanceInr, existingInitialBalanceInr);
      expect(updatedWallet.lockedInr, 1000.0);
    });
  });

  group('Empty portfolio initialization', () {
    test('empty portfolio value equals one crore INR', () {
      final portfolio = Portfolio(
        wallet: VirtualWallet.initial(),
        holdings: const [],
        totalRealisedPnlInr: 0.0,
      );

      expect(portfolio.holdingsValueInr, 0.0);
      expect(
        portfolio.totalPortfolioValueInr,
        VirtualWallet.startingBalanceInr,
      );
      expect(
        FinancialMath.inrToPaise(portfolio.totalPortfolioValueInr),
        1000000000,
      );
      expect(portfolio.totalUnrealisedPnlInr, 0.0);
      expect(portfolio.overallPnlPercent, 0.0);
    });
  });
}
