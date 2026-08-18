import 'package:flutter/material.dart';
import 'package:cryptoedu/shared/widgets/crypto_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';
import '../../../shared/models/holding.dart';
import '../../../shared/widgets/trade_card.dart';
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
        data: (portfolio) => Consumer(
          builder: (context, ref, child) {
            final isOffline = ref.watch(connectivityProvider) == ConnectivityStatus.offline;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOffline)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: OfflineStateWidget(
                        compact: true,
                        message: 'Showing cached data',
                      ),
                    ),
                  TradeCard(
                semanticLabel: 'Virtual portfolio balances',
                child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Available Cash',
                                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                                overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                              FinancialMath.formatInr(
                                  portfolio.wallet.availableBalanceInr),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Holdings Valuation',
                                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                                overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                              FinancialMath.formatInr(
                                  portfolio.holdingsValueInr),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],

                ),
              ),
              SizedBox(height: 20),
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
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${h.symbol} (${h.quantity.toStringAsFixed(4)})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Avg Entry: ${FinancialMath.formatInr(h.averageEntryPriceInr)}',
                                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    FinancialMath.formatInr(h.currentValueInr),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${h.unrealisedPnlInr >= 0 ? '+' : ''}${FinancialMath.formatInr(h.unrealisedPnlInr)} (${h.unrealisedPnlPercent.toStringAsFixed(2)}%)',
                                    style: TextStyle(
                                      color: h.unrealisedPnlInr >= 0 ? AppColors.profit : AppColors.loss,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                SizedBox(
                                  height: 32,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      backgroundColor: AppColors.loss.withValues(alpha: 0.1),
                                      foregroundColor: AppColors.loss,
                                    ),
                                    onPressed: () => _closePosition(context, ref, h),
                                    child: const Text('Close'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  }).toList(),
                ),
            ],
          ),
        );
        },
      ),
        loading: () => const Center(child: CryptoLoadingIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.loss, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load portfolio', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(err.toString(), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(portfolioProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


