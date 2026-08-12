import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/shared/models/virtual_wallet.dart';

void main() {
  group('VirtualWallet', () {
    test('initial factory sets default values correctly', () {
      final wallet = VirtualWallet.initial();
      expect(wallet.balanceInr, 10000000.0);
      expect(wallet.lockedInr, 0.0);
      expect(wallet.initialBalanceInr, 10000000.0);
      expect(wallet.availableBalanceInr, 10000000.0);
    });

    test('availableBalanceInr calculates correctly', () {
      const wallet = VirtualWallet(
        balanceInr: 50000.0,
        lockedInr: 10000.0,
      );
      expect(wallet.availableBalanceInr, 40000.0);
    });

    test('copyWith updates fields correctly', () {
      final wallet = VirtualWallet.initial().copyWith(
        balanceInr: 120000.0,
        lockedInr: 20000.0,
      );
      expect(wallet.balanceInr, 120000.0);
      expect(wallet.lockedInr, 20000.0);
      expect(wallet.initialBalanceInr, 10000000.0); 
      expect(wallet.availableBalanceInr, 100000.0);
    });
  });
}
