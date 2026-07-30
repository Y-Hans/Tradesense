import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';
import '../../../shared/models/holding.dart';
import '../../../shared/widgets/trade_card.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/offline_state_widget.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  Future<void> _closePosition(
    BuildContext context,
    WidgetRef ref,
    Holding holding,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Close simulated ${holding.symbol} position?'),
        content: Text(
          'This closes ${holding.quantity.toStringAsFixed(4)} ${holding.symbol} '
          'using the current simulated market price.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep position'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Close virtual trade'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      final marketRepository = ref.read(marketRepositoryProvider);
      final tradingRepository = ref.read(tradingRepositoryProvider);
      final ticker = await marketRepository.getTicker(holding.symbol);

      await tradingRepository.executeMarketSell(
        symbol: holding.symbol,
        quantity: holding.quantity,
        executionPriceInr: ticker.priceInr,
      );
      ref.invalidate(portfolioProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${holding.symbol} virtual position closed.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to close virtual position: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(
      connectivityProvider
          .select((status) => status == ConnectivityStatus.offline),
    );
    final portfolioAsync = ref.watch(portfolioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/trade-history'),
          )
        ],
      ),
      body: portfolioAsync.when(
        data: (portfolio) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOffline)
                OfflineStateWidget(
                  message: AppStrings.portfolioOfflineNotice,
                  compact: true,
                  footer: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.outline, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '${AppStrings.portfolioOfflineNotice} • ${AppStrings.portfolioOfflineLastUpdatedPrefix} just now',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              TradeCard(
                semanticLabel: 'Virtual portfolio balances',
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Available Cash',
                            style: TextStyle(color: AppColors.textSecondary)),
                        Text(
                            FinancialMath.formatInr(
                                portfolio.wallet.availableBalanceInr),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Holdings Valuation',
                            style: TextStyle(color: AppColors.textSecondary)),
                        Text(
                            FinancialMath.formatInr(portfolio.holdingsValueInr),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Active Holdings',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (portfolio.holdings.isEmpty)
                const TradeCard(
                  child: Center(
                      child: Text(
                          'No active holdings. Place a trade from Markets!')),
                )
              else
                Column(
                  children: portfolio.holdings.map((h) {
                    return TradeCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                            '${h.symbol} (${h.quantity.toStringAsFixed(4)})',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Avg Entry: ${FinancialMath.formatInr(h.averageEntryPriceInr)}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(FinancialMath.formatInr(h.currentValueInr),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                              '${FinancialMath.formatInr(h.unrealisedPnlInr)} (${h.unrealisedPnlPercent.toStringAsFixed(2)}%)',
                              style: TextStyle(
                                  color: h.unrealisedPnlInr >= 0
                                      ? AppColors.profit
                                      : AppColors.loss,
                                  fontSize: 12),
                            ),
                            TextButton(
                              onPressed: () => _closePosition(context, ref, h),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Text('Error: $err'),
      ),
    );
  }
}
