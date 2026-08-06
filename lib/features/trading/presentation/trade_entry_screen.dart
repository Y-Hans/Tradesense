import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:design_system/design_system.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';
import '../../../shared/widgets/trade_card.dart';

/// Lets learners choose a supported asset before opening the simulator order
/// flow. This screen does not execute or configure a real-money trade.
class TradeEntryScreen extends ConsumerWidget {
  const TradeEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(supportedAssetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Virtual Trade')),
      body: assetsAsync.when(
        data: (assets) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TradeCard(
              semanticLabel: 'Simulated trading notice',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school_outlined, color: AppColors.primaryCyan),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice with virtual cash',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Choose an asset to practise a simulated order. '
                          'No cryptocurrency is bought or sold.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choose an asset',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...assets.map(
              (asset) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TradeCard(
                  semanticLabel: 'Practice a virtual ${asset.symbol} trade',
                  onTap: () => context.push('/trade/${asset.symbol}'),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            AppColors.primaryCyan.withValues(alpha: 0.18),
                        child: Text(
                          asset.symbol[0],
                          style: const TextStyle(
                            color: AppColors.primaryCyan,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              asset.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(asset.symbol),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            FinancialMath.formatInr(asset.currentPriceInr),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${asset.change24hPercent >= 0 ? '+' : ''}${asset.change24hPercent.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: asset.change24hPercent >= 0
                                  ? AppColors.successGreen
                                  : AppColors.errorRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load simulated markets: $error'),
          ),
        ),
      ),
    );
  }
}
