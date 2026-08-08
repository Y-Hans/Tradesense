import 'package:cryptoedu/shared/widgets/bitcoin_loader.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/trading_use_case_providers.dart';
import '../../../core/utils/financial_math.dart';

import '../../portfolio/domain/portfolio_engine_result.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(
      connectivityProvider
          .select((status) => status == ConnectivityStatus.offline),
    );
    final portfolioAsync = ref.watch(portfolioSnapshotProvider);

    return AppScaffold(
      showBackButton: false,
      title: 'Portfolio',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOffline)
            const Icon(Icons.wifi_off, color: AppColors.warningOrange, size: 20),
          const SizedBox(width: AppSpacing.md),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/trade-history'),
            tooltip: 'Trade History',
          ),
        ],
      ),
      body: isOffline && portfolioAsync.value == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('You are currently offline.'),
                  TextButton(
                    onPressed: () => ref.refresh(portfolioSnapshotProvider),
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            )
          : portfolioAsync.when(
              data: (portfolio) => _buildContent(context, ref, portfolio, isOffline),
              loading: () => const Center(
                child: AdaptiveLoader(),
              ),
              error: (err, stack) => EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Error loading portfolio',
                description: err.toString(),
                primaryAction: PrimaryButton(
                  text: 'Retry',
                  onPressed: () => ref.invalidate(portfolioSnapshotProvider),
                ),
              ),
            ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, PortfolioSnapshot portfolio, bool isOffline) {
    final hasHoldings = portfolio.assetSummaries.isNotEmpty;

    return RefreshIndicator(
      color: AppColors.primaryCyan,
      backgroundColor: Theme.of(context).cardTheme.color,
      onRefresh: () async => ref.invalidate(portfolioSnapshotProvider),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (isOffline)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: const Text('You are currently offline (Showing cached data)'),
                backgroundColor: Colors.orange.withOpacity(0.2),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Total Equity Card
          AppCard(
            isActive: true,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Text(
                  'Total Equity',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  FinancialMath.formatInr(portfolio.totals.portfolioValueInr),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _StatColumn(
                        label: 'Available Cash',
                        value: FinancialMath.formatInr(
                            portfolio.wallet.availableBalanceInr),
                        valueColor: AppColors.successGreen,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.border,
                    ),
                    Expanded(
                      child: _StatColumn(
                        label: 'Invested',
                        value: FinancialMath.formatInr(portfolio.totals.cryptoValueInr),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Integration Point (AI Layer)
          const AIInsightCard(
            title: 'Portfolio Health',
            content:
                'Your portfolio is well diversified. Consider keeping at least 30% of your equity in cash to take advantage of market dips. Avoid holding losing positions too long without a stop-loss.',
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Active Holdings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Holdings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (hasHoldings)
                Text(
                  '${portfolio.assetSummaries.length} positions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (!hasHoldings)
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'No Active Positions',
                description: 'You currently have no open positions. Explore the markets to find trading opportunities.',
                primaryAction: PrimaryButton(
                  text: 'Explore Markets',
                  onPressed: () => context.go('/markets'),
                ),
              ),
            )
          else
            ...portfolio.assetSummaries.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _HoldingCard(holding: h),
                )),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _HoldingCard extends StatelessWidget {
  final AssetSummary holding;

  const _HoldingCard({required this.holding});

  @override
  Widget build(BuildContext context) {
    final isProfit = holding.unrealizedProfitLossInr >= 0;
    final pnlColor = isProfit ? AppColors.successGreen : AppColors.errorRed;
    final initial = holding.assetSymbol.length >= 2
        ? holding.assetSymbol.substring(0, 2).toUpperCase()
        : holding.assetSymbol.toUpperCase();

    return AppCard(
      hasBorder: true,
      onTap: () => context.push('/asset/${holding.assetSymbol}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryCyan.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.primaryCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      holding.assetSymbol,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${holding.quantity.toStringAsFixed(4)} tokens',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    FinancialMath.formatInr(holding.currentValueInr),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isProfit ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: pnlColor,
                        size: 16,
                      ),
                      Text(
                        '${FinancialMath.formatInr(holding.unrealizedProfitLossInr.abs())} (${holding.returnPercent.abs().toStringAsFixed(2)}%)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: pnlColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Avg Entry: ${FinancialMath.formatInr(holding.averageEntryPriceInr)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              GestureDetector(
                onTap: () => context.push('/trade', extra: holding.assetSymbol),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Text(
                    'SELL',
                    style: TextStyle(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
