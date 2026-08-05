import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';

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

    return AppScaffold(
      title: 'Trade ${widget.symbol}',
      body: FutureBuilder(
        future: marketRepo.getTicker(widget.symbol),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCyan),
            );
          }
          final ticker = snapshot.data!;
          final totalInr = quantity * ticker.priceInr;
          final stopLossPrice = isBuy
              ? ticker.priceInr * (1 - (stopLossPercent / 100))
              : ticker.priceInr * (1 + (stopLossPercent / 100));

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Integration Point (AI Layer)
              AIInsightCard(
                title: 'Pre-Trade Coach',
                content:
                    '${widget.symbol} is showing moderate volatility today. Setting a stop-loss is highly recommended to protect your capital.',
              ),
              const SizedBox(height: AppSpacing.xl),

              // Live Price Card
              AppCard(
                hasBorder: true,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Price',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.symbol,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Text(
                      FinancialMath.formatInr(ticker.priceInr),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryCyan,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Side Selection
              Row(
                children: [
                  Expanded(
                    child: _SideButton(
                      label: 'BUY',
                      isSelected: isBuy,
                      activeColor: AppColors.successGreen,
                      onTap: () => setState(() => isBuy = true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SideButton(
                      label: 'SELL',
                      isSelected: !isBuy,
                      activeColor: AppColors.errorRed,
                      onTap: () => setState(() => isBuy = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Quantity
              Text(
                'Quantity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        Text(
                          '${quantity.toStringAsFixed(3)} ${widget.symbol}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: isBuy
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                        thumbColor: isBuy
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                      ),
                      child: Slider(
                        value: quantity,
                        min: 0.01,
                        max: 2.0,
                        divisions: 199,
                        onChanged: (val) => setState(() => quantity = val),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Value',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        Text(
                          FinancialMath.formatInr(totalInr),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Stop Loss
              Text(
                'Risk Management',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Set Stop-Loss',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      subtitle: Text(
                        useStopLoss
                            ? 'Trigger at ${FinancialMath.formatInr(stopLossPrice)} (-${stopLossPercent.toStringAsFixed(1)}%)'
                            : 'No protection',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      value: useStopLoss,
                      activeColor: AppColors.primaryCyan,
                      onChanged: (val) => setState(() => useStopLoss = val),
                    ),
                    if (useStopLoss) ...[
                      const Divider(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Risk %',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          Text(
                            '-${stopLossPercent.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warningOrange,
                                ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.warningOrange,
                          thumbColor: AppColors.warningOrange,
                        ),
                        child: Slider(
                          value: stopLossPercent,
                          min: 1.0,
                          max: 20.0,
                          divisions: 19,
                          onChanged: (val) =>
                              setState(() => stopLossPercent = val),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PrimaryButton(
            text: 'EXECUTE ${isBuy ? "BUY" : "SELL"} ORDER',
            onPressed: _executeTrade,
          ),
        ),
      ),
    );
  }

  Future<void> _executeTrade() async {
    final tradingRepo = ref.read(tradingRepositoryProvider);
    final marketRepo = ref.read(marketRepositoryProvider);

    try {
      final ticker = await marketRepo.getTicker(widget.symbol);

      final stopLossPrice = isBuy
          ? ticker.priceInr * (1 - (stopLossPercent / 100))
          : ticker.priceInr * (1 + (stopLossPercent / 100));

      final trade = isBuy
          ? await tradingRepo.executeMarketBuy(
              symbol: widget.symbol,
              quantity: quantity,
              executionPriceInr: ticker.priceInr,
              stopLossPriceInr: useStopLoss ? stopLossPrice : null,
            )
          : await tradingRepo.executeMarketSell(
              symbol: widget.symbol,
              quantity: quantity,
              executionPriceInr: ticker.priceInr,
            );

      ref.invalidate(portfolioProvider);
      if (mounted) {
        context.push('/coach-result/${trade.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to execute trade: $e')),
        );
      }
    }
  }
}

class _SideButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _SideButton({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? activeColor : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}
