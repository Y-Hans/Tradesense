import 'package:flutter_test/flutter_test.dart';
import 'package:cryptoedu/core/utils/financial_math.dart';

void main() {
  group('FinancialMath Tests', () {
    test('inrToPaise and paiseToInr accuracy', () {
      expect(FinancialMath.inrToPaise(100.50), 10050);
      expect(FinancialMath.paiseToInr(10050), 100.50);
      expect(FinancialMath.inrToPaise(100000.00), 10000000);
    });

    test('formatInr formatting', () {
      expect(FinancialMath.formatInr(100000.0), '₹1,00,000.00');
      expect(FinancialMath.formatInr(5850000.50), '₹58,50,000.50');
      expect(FinancialMath.formatInr(-1250.0), '-₹1,250.00');
    });

    test('percentageChange accuracy', () {
      expect(FinancialMath.percentageChange(100.0, 110.0), 10.0);
      expect(FinancialMath.percentageChange(100.0, 90.0), -10.0);
    });
  });
}
