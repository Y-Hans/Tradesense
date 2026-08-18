import 'package:flutter/material.dart';
import '../../../core/networking/dio_client_factory.dart';
import '../../../core/pricing/currency_converter.dart';
import '../../../core/pricing/public_fx_provider.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final _amountController = TextEditingController(text: '100000');
  String _from = 'INR';
  String _to = 'USD';
  Future<CurrencyConversion>? _conversion;

  CurrencyConverter get _converter => CurrencyConverter(
        fxProvider: PublicFxProvider(
          usdDio: DioClientFactory.forUsdFx(),
          coinGeckoDio: DioClientFactory.forCoinGecko(),
        ),
      );

  void _convert() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) return;
    setState(() {
      _conversion = _converter.convert(
          amount: amount, fromCurrency: _from, toCurrency: _to);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Currency Converter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Input amount')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: DropdownButtonFormField<String>(
                    value: _from,
                    items: const ['INR', 'USD', 'USDT']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _from = v!))),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.swap_horiz)),
            Expanded(
                child: DropdownButtonFormField<String>(
                    value: _to,
                    items: const ['INR', 'USD', 'USDT']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _to = v!))),
          ]),
          const SizedBox(height: 16),
          FilledButton(onPressed: _convert, child: const Text('Use live rate')),
          const SizedBox(height: 24),
          if (_conversion != null)
            FutureBuilder<CurrencyConversion>(
              future: _conversion,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError)
                  return Text('Live conversion unavailable. Please retry.');
                final value = snapshot.data!;
                return Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Live ${value.rate.fromCurrency}/${value.rate.toCurrency} rate: ${value.rate.rate}'),
                              Text(
                                  'Gross converted amount: ${value.grossAmount.toStringAsFixed(2)} ${value.rate.toCurrency}'),
                              Text(
                                  'Conversion fee: ${(value.fee.fraction * 100).toStringAsFixed(2)}%'),
                              Text(
                                  'Fee: ${value.feeAmount.toStringAsFixed(2)} ${value.rate.toCurrency}'),
                              Text(
                                  'You receive: ${value.finalAmount.toStringAsFixed(2)} ${value.rate.toCurrency}'),
                              Text('Rate source: ${value.rate.source}'),
                              Text(
                                  'Rate timestamp: ${value.rate.timestamp.toLocal()}'),
                            ])));
              },
            ),
        ],
      ),
    );
  }
}
