import 'package:decimal/decimal.dart';

class FinancialMath {
  /// Converts double INR to integer paise to avoid IEEE floating-point errors
  static int inrToPaise(double inr) {
    return (Decimal.parse(inr.toStringAsFixed(2)) * Decimal.fromInt(100))
        .toBigInt()
        .toInt();
  }

  /// Converts integer paise back to double INR
  static double paiseToInr(int paise) {
    return (Decimal.fromInt(paise) / Decimal.fromInt(100)).toDouble();
  }

  /// Calculates percentage change deterministically
  static double percentageChange(double initial, double current) {
    if (initial == 0) return 0.0;
    final change = ((current - initial) / initial) * 100.0;
    return double.parse(change.toStringAsFixed(2));
  }

  /// Formats INR currency string in Indian Numbering System (e.g., ₹1,00,000.00)
  static String formatInr(double amount) {
    final absAmount = amount.abs().toStringAsFixed(2);
    final parts = absAmount.split('.');
    String integerPart = parts[0];
    final decimalPart = parts[1];

    if (integerPart.length > 3) {
      final lastThree = integerPart.substring(integerPart.length - 3);
      final remaining = integerPart.substring(0, integerPart.length - 3);
      final buffer = StringBuffer();
      for (int i = 0; i < remaining.length; i++) {
        if (i > 0 && (remaining.length - i) % 2 == 0) {
          buffer.write(',');
        }
        buffer.write(remaining[i]);
      }
      integerPart = '${buffer.toString()},$lastThree';
    }

    final sign = amount < 0 ? '-' : '';
    return '$sign₹$integerPart.$decimalPart';
  }
}
