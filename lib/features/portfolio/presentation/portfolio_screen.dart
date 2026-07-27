import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

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
        data: (portfolio) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: AppColors.card,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                              FinancialMath.formatInr(
                                  portfolio.holdingsValueInr),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Active Holdings',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (portfolio.holdings.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                        child: Text(
                            'No active holdings. Place a trade from Markets!')),
                  ),
                )
              else
                Column(
                  children: portfolio.holdings.map((h) {
                    return Card(
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
