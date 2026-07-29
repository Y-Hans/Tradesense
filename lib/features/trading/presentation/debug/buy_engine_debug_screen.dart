import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../features/trading/domain/buy_trade_result.dart';
import '../../../../features/trading/domain/trading_domain_service.dart';
import '../../../../shared/models/crypto_asset.dart';
import '../../../../shared/models/holding.dart';
import '../../../../shared/models/market_ticker.dart';
import '../../../../shared/models/virtual_wallet.dart';

class BuyEngineDebugScreen extends StatefulWidget {
  const BuyEngineDebugScreen({super.key});

  @override
  State<BuyEngineDebugScreen> createState() => _BuyEngineDebugScreenState();
}

class _BuyEngineDebugScreenState extends State<BuyEngineDebugScreen> {
  static const _service = TradingDomainService();
  static const _userId = 'debug_user_laksh';
  static const _holdingId = 'debug_holding_btc';
  static const _firstBuyAmountInr = 100000.0;
  static const _secondBuyAmountInr = 200000.0;
  static const _firstPriceInr = 5000000.0;
  static const _secondPriceInr = 5500000.0;
  static final _baseTime = DateTime.utc(2026, 7, 28, 10);
  static const _asset = CryptoAsset(
    symbol: 'BTC',
    name: 'Bitcoin',
    iconUrl: 'assets/icons/btc.png',
    currentPriceInr: _firstPriceInr,
    change24hPercent: 1.0,
    isSupportedV1: true,
  );

  final _amountController = TextEditingController(
    text: _firstBuyAmountInr.toStringAsFixed(0),
  );
  final _priceController = TextEditingController(
    text: _firstPriceInr.toStringAsFixed(0),
  );

  VirtualWallet _wallet = VirtualWallet.initial();
  Holding? _holding;
  BuyTradeResult? _latestResult;
  String? _inputError;
  String? _unexpectedError;
  int _tradeSequence = 1;

  @override
  void dispose() {
    _amountController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final holding = _holding;
    final price = double.tryParse(_priceController.text.trim());

    return Scaffold(
      appBar: AppBar(
        title: const Text('BUY Engine Debug'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DEBUG ONLY - deterministic, in-memory, no persistence or live market APIs.',
              style: TextStyle(
                color: AppColors.discipline,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Current State',
              children: [
                _DebugRow(
                  label: 'Wallet balance',
                  value: _formatInr(_wallet.balanceInr),
                  valueKey: const Key('buy-engine-wallet-balance'),
                ),
                _DebugRow(
                  label: 'Available balance',
                  value: _formatInr(_wallet.availableBalanceInr),
                ),
                _DebugRow(
                  label: 'Selected asset',
                  value: '${_asset.symbol} - ${_asset.name}',
                ),
                _DebugRow(
                  label: 'Simulated market price',
                  value: price == null ? 'Invalid input' : _formatInr(price),
                ),
                _DebugRow(
                  label: 'Existing holding',
                  value: holding == null
                      ? 'No holding'
                      : '${_formatQuantity(holding.quantity)} ${holding.symbol}',
                  valueKey: const Key('buy-engine-holding-quantity'),
                ),
                _DebugRow(
                  label: 'Current cost basis',
                  value: _formatInr(holding?.totalCostInr ?? 0),
                ),
                _DebugRow(
                  label: 'Average entry price',
                  value: _formatInr(holding?.averageEntryPriceInr ?? 0),
                  valueKey: const Key('buy-engine-average-entry'),
                ),
                _DebugRow(
                  label: 'Latest result status',
                  value: _latestStatus,
                  valueKey: const Key('buy-engine-latest-status'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Inputs',
              children: [
                TextField(
                  key: const Key('buy-engine-amount-field'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'INR buy amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('buy-engine-price-field'),
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Market price INR',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      key: const Key('buy-engine-first-scenario-button'),
                      onPressed: () => _setScenario(
                        amountInr: _firstBuyAmountInr,
                        priceInr: _firstPriceInr,
                      ),
                      child: const Text('Use First Scenario'),
                    ),
                    OutlinedButton(
                      key: const Key('buy-engine-second-scenario-button'),
                      onPressed: () => _setScenario(
                        amountInr: _secondBuyAmountInr,
                        priceInr: _secondPriceInr,
                      ),
                      child: const Text('Use Second Scenario'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  key: const Key('buy-engine-execute-button'),
                  onPressed: _executeBuy,
                  child: const Text('Execute BUY'),
                ),
                OutlinedButton(
                  key: const Key('buy-engine-reset-button'),
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
                OutlinedButton(
                  key: const Key('buy-engine-insufficient-funds-button'),
                  onPressed: _testInsufficientFunds,
                  child: const Text('Test Insufficient Funds'),
                ),
                OutlinedButton(
                  key: const Key('buy-engine-invalid-amount-button'),
                  onPressed: _testInvalidAmount,
                  child: const Text('Test Invalid Amount'),
                ),
                OutlinedButton(
                  key: const Key('buy-engine-stale-ticker-button'),
                  onPressed: _testStaleTicker,
                  child: const Text('Test Stale Ticker'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ResultPanel(
              result: _latestResult,
              inputError: _inputError,
              unexpectedError: _unexpectedError,
            ),
          ],
        ),
      ),
    );
  }

  String get _latestStatus {
    if (_inputError != null) return 'INPUT ERROR';
    if (_unexpectedError != null) return 'EXCEPTION';
    final result = _latestResult;
    if (result == null) return 'None';
    if (result is BuyTradeSuccess) return 'SUCCESS';
    return 'REJECTED';
  }

  void _setScenario({
    required double amountInr,
    required double priceInr,
  }) {
    setState(() {
      _amountController.text = amountInr.toStringAsFixed(0);
      _priceController.text = priceInr.toStringAsFixed(0);
    });
  }

  void _executeBuy({
    double? amountOverride,
    double? priceOverride,
    bool useStaleTicker = false,
  }) {
    final buyAmountInr = amountOverride ?? _parseInput(_amountController);
    final priceInr = priceOverride ?? _parseInput(_priceController);

    if (buyAmountInr == null || priceInr == null) {
      setState(() {
        _latestResult = null;
        _unexpectedError = null;
        _inputError =
            'Invalid INR amount or market price text. Enter numeric values.';
      });
      return;
    }

    final evaluatedAt = _baseTime.add(Duration(seconds: _tradeSequence * 10));
    final tickerTimestamp = useStaleTicker
        ? evaluatedAt.subtract(
            TradingDomainService.defaultTickerFreshness +
                const Duration(seconds: 1),
          )
        : evaluatedAt;
    final ticker = _ticker(priceInr: priceInr, timestamp: tickerTimestamp);

    try {
      final result = _service.calculateBuy(
        wallet: _wallet,
        asset: _asset,
        ticker: ticker,
        buyAmountInr: buyAmountInr,
        existingHolding: _holding,
        executedAt: evaluatedAt.add(const Duration(seconds: 5)),
        evaluatedAt: evaluatedAt,
        tradeId: 'debug_buy_trade_$_tradeSequence',
        userId: _userId,
        holdingId: _holdingId,
        disciplineScoreAtTrade: 80,
        riskScoreAtTrade: 25,
      );

      setState(() {
        _latestResult = result;
        _inputError = null;
        _unexpectedError = null;
        _tradeSequence += 1;
        if (result is BuyTradeSuccess) {
          _wallet = result.updatedWallet;
          _holding = result.updatedHolding;
        }
      });
    } catch (error) {
      setState(() {
        _latestResult = null;
        _inputError = null;
        _unexpectedError = error.toString();
      });
    }
  }

  void _testInsufficientFunds() {
    _executeBuy(amountOverride: _wallet.availableBalanceInr + 1);
  }

  void _testInvalidAmount() {
    _executeBuy(amountOverride: 0);
  }

  void _testStaleTicker() {
    _executeBuy(useStaleTicker: true);
  }

  void _reset() {
    setState(() {
      _wallet = VirtualWallet.initial();
      _holding = null;
      _latestResult = null;
      _inputError = null;
      _unexpectedError = null;
      _tradeSequence = 1;
      _amountController.text = _firstBuyAmountInr.toStringAsFixed(0);
      _priceController.text = _firstPriceInr.toStringAsFixed(0);
    });
  }

  double? _parseInput(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', ''));
  }

  MarketTicker _ticker({
    required double priceInr,
    required DateTime timestamp,
  }) {
    final positivePrice = priceInr.isFinite && priceInr > 0 ? priceInr : 1.0;
    return MarketTicker(
      symbol: _asset.symbol,
      priceInr: priceInr,
      high24h: positivePrice * 1.1,
      low24h: positivePrice * 0.9,
      volume24h: 1000000,
      timestamp: timestamp,
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.result,
    required this.inputError,
    required this.unexpectedError,
  });

  final BuyTradeResult? result;
  final String? inputError;
  final String? unexpectedError;

  @override
  Widget build(BuildContext context) {
    final inputError = this.inputError;
    final unexpectedError = this.unexpectedError;
    final result = this.result;

    if (inputError != null) {
      return _Section(
        title: 'Debug Input Error',
        children: [
          Text(
            inputError,
            key: const Key('buy-engine-input-error'),
            style: const TextStyle(color: AppColors.discipline),
          ),
        ],
      );
    }

    if (unexpectedError != null) {
      return _Section(
        title: 'Unexpected Exception',
        children: [
          Text(
            unexpectedError,
            key: const Key('buy-engine-exception'),
            style: const TextStyle(color: AppColors.loss),
          ),
        ],
      );
    }

    if (result is BuyTradeSuccess) {
      final trade = result.trade;
      return _Section(
        title: 'Successful BUY',
        children: [
          _DebugRow(
            label: 'Previous wallet balance',
            value: _formatInr(result.previousWalletBalanceInr),
          ),
          _DebugRow(
            label: 'New wallet balance',
            value: _formatInr(result.newWalletBalanceInr),
          ),
          _DebugRow(
            label: 'Purchased quantity',
            value: _formatQuantity(result.purchasedQuantity),
          ),
          _DebugRow(
            label: 'Previous holding quantity',
            value: _formatQuantity(result.previousHoldingQuantity),
          ),
          _DebugRow(
            label: 'New holding quantity',
            value: _formatQuantity(result.newHoldingQuantity),
          ),
          _DebugRow(
            label: 'Previous cost basis',
            value: _formatInr(result.previousCostBasisInr),
          ),
          _DebugRow(
            label: 'New cost basis',
            value: _formatInr(result.newCostBasisInr),
          ),
          _DebugRow(
            label: 'Previous average entry',
            value: _formatInr(result.previousAverageEntryPriceInr),
          ),
          _DebugRow(
            label: 'New average entry',
            value: _formatInr(result.newAverageEntryPriceInr),
          ),
          _DebugRow(
            label: 'Execution price',
            value: _formatInr(result.executionPriceInr),
          ),
          _DebugRow(label: 'Trade ID', value: trade.id),
          _DebugRow(
            label: 'Trade total',
            value: _formatInr(trade.totalAmountInr),
          ),
          _DebugRow(
            label: 'Trade quantity',
            value: _formatQuantity(trade.quantity),
          ),
          _DebugRow(
            label: 'Execution timestamp',
            value: trade.timestamp.toIso8601String(),
          ),
        ],
      );
    }

    if (result is BuyTradeRejected) {
      return _Section(
        title: 'Rejected BUY',
        children: [
          _DebugRow(
            label: 'Failure code',
            value: result.failure.code.toString(),
            valueKey: const Key('buy-engine-failure-code'),
          ),
          _DebugRow(
            label: 'Message',
            value: result.failure.message,
          ),
          const Text(
            'Wallet and holding state unchanged.',
            key: Key('buy-engine-rejection-state-note'),
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return const _Section(
      title: 'Latest Result',
      children: [
        Text('No BUY calculation has been executed yet.'),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({
    required this.label,
    required this.value,
    this.valueKey,
  });

  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 7,
            child: Text(
              value,
              key: valueKey,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatInr(double amount) {
  final absAmount = amount.abs().toStringAsFixed(2);
  final parts = absAmount.split('.');
  var integerPart = parts[0];
  final decimalPart = parts[1];

  if (integerPart.length > 3) {
    final lastThree = integerPart.substring(integerPart.length - 3);
    final remaining = integerPart.substring(0, integerPart.length - 3);
    final buffer = StringBuffer();
    for (var i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }
    integerPart = '${buffer.toString()},$lastThree';
  }

  final sign = amount < 0 ? '-' : '';
  return '$sign\u20B9$integerPart.$decimalPart';
}

String _formatQuantity(double quantity) {
  final fixed = quantity.abs() >= 1
      ? quantity.toStringAsFixed(8)
      : quantity.toStringAsPrecision(12);
  return fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '.0');
}
