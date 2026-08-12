import 'package:flutter/material.dart';
import 'package:cryptoedu/shared/widgets/crypto_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';
import '../../../shared/widgets/trade_card.dart';

class TradeScreen extends ConsumerStatefulWidget {
  final String symbol;
  const TradeScreen({super.key, required this.symbol});

  @override
  ConsumerState<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends ConsumerState<TradeScreen> {
  bool isBuy = true;
  double quantity = 0.1;
  bool useStopLoss = true;
  double stopLossPercent = 5.0;

  @override
  Widget build(BuildContext context) {
    final marketRepo = ref.watch(marketRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Trade ${widget.symbol}'),
      ),
      body: FutureBuilder(
        future: marketRepo.getTicker(widget.symbol),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CryptoLoadingIndicator());
          }
          final ticker = snapshot.data!;
          final totalInr = quantity * ticker.priceInr;
          final stopLossPrice = isBuy
              ? ticker.priceInr * (1 - (stopLossPercent / 100))
              : ticker.priceInr * (1 + (stopLossPercent / 100));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TradeCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${widget.symbol} Live Price',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      Text(FinancialMath.formatInr(ticker.priceInr),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.electricCyan)),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isBuy ? AppColors.profit : Theme.of(context).cardColor,
                        ),
                        onPressed: () => setState(() => isBuy = true),
                        child: Text('VIRTUAL BUY',
                            style: TextStyle(
                                color: isBuy ? Colors.white : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black),
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              !isBuy ? AppColors.loss : Theme.of(context).cardColor,
                        ),
                        onPressed: () => setState(() => isBuy = false),
                        child: Text('VIRTUAL SELL',
                            style: TextStyle(
                                color: !isBuy ? Colors.white : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black),
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Quantity',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: quantity,
                        min: 0.01,
                        max: 2.0,
                        divisions: 199,
                        label: quantity.toStringAsFixed(2),
                        onChanged: (val) => setState(() => quantity = val),
                      ),
                    ),
                    Text('${quantity.toStringAsFixed(2)} ${widget.symbol}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                Text('Total Order Value: ${FinancialMath.formatInr(totalInr)}',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('Set Stop-Loss Protection'),
                  subtitle: Text(useStopLoss
                      ? 'Trigger at ${FinancialMath.formatInr(stopLossPrice)} (-$stopLossPercent%)'
                      : 'No stop-loss protection'),
                  value: useStopLoss,
                  onChanged: (val) => setState(() => useStopLoss = val),
                ),
                if (useStopLoss)
                  Slider(
                    value: stopLossPercent,
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    label: '$stopLossPercent%',
                    onChanged: (val) => setState(() => stopLossPercent = val),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isBuy ? AppColors.profit : AppColors.loss,
                    ),
                    onPressed: () async {
                      final tradingRepo = ref.read(tradingRepositoryProvider);
                      final trade = isBuy
                          ? await tradingRepo.executeMarketBuy(
                              symbol: widget.symbol,
                              quantity: quantity,
                              executionPriceInr: ticker.priceInr,
                              stopLossPriceInr:
                                  useStopLoss ? stopLossPrice : null,
                            )
                          : await tradingRepo.executeMarketSell(
                              symbol: widget.symbol,
                              quantity: quantity,
                              executionPriceInr: ticker.priceInr,
                            );

                      ref.invalidate(portfolioProvider);
                      if (context.mounted) {
                        context.push('/coach-result/${trade.id}');
                      }
                    },
                    child: Text('EXECUTE ${isBuy ? "BUY" : "SELL"} ORDER',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


