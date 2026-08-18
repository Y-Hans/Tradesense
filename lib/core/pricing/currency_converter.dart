import 'market_pricing.dart';

class ConversionFee {
  final double fraction;
  const ConversionFee.zero() : fraction = 0;
  const ConversionFee(this.fraction) : assert(fraction >= 0 && fraction < 1);
}

class CurrencyConversion {
  final double inputAmount;
  final ExchangeRate rate;
  final double grossAmount;
  final double feeAmount;
  final double finalAmount;
  final ConversionFee fee;

  const CurrencyConversion({
    required this.inputAmount,
    required this.rate,
    required this.grossAmount,
    required this.feeAmount,
    required this.finalAmount,
    required this.fee,
  });
}

class CurrencyConverter {
  final FxProvider fxProvider;
  final ConversionFee fee;

  const CurrencyConverter(
      {required this.fxProvider, this.fee = const ConversionFee.zero()});

  Future<CurrencyConversion> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (!amount.isFinite || amount < 0) {
      throw const ExchangeRateUnavailable('invalid', 'amount');
    }
    final rate = await fxProvider.getExchangeRate(fromCurrency, toCurrency);
    if (!rate.isValid) throw ExchangeRateUnavailable(fromCurrency, toCurrency);
    final gross = amount * rate.rate;
    final feeAmount = gross * fee.fraction;
    return CurrencyConversion(
      inputAmount: amount,
      rate: rate,
      grossAmount: gross,
      feeAmount: feeAmount,
      finalAmount: gross - feeAmount,
      fee: fee,
    );
  }
}
