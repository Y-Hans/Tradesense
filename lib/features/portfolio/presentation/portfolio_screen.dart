import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/offline_state_widget.dart';
import '../../../shared/models/holding.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(
      connectivityProvider
          .select((status) => status == ConnectivityStatus.offline),
    );
    final portfolioAsync = ref.watch(portfolioProvider);

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
          ? const Center(
              child: OfflineStateWidget(
                title: 'Portfolio Offline',
                message: AppStrings.portfolioOfflineNotice,
              ),
            )
          : portfolioAsync.when(
              data: (portfolio) => _buildContent(context, ref, portfolio, isOffline),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryCyan),
              ),
              error: (err, stack) => EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Error loading portfolio',
                description: err.toString(),
                primaryAction: PrimaryButton(
                  text: 'Retry',
                  onPressed: () => ref.invalidate(portfolioProvider),
                ),
              ),
            ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, portfolio, bool isOffline) {
    final hasHoldings = portfolio.holdings.isNotEmpty;

    return RefreshIndicator(
      color: AppColors.primaryCyan,
      backgroundColor: Theme.of(context).cardTheme.color,
      onRefresh: () async => ref.invalidate(portfolioProvider),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (isOffline) ...[
            const StatusChip(
              label: '${AppStrings.portfolioOfflineNotice} (Showing cached data)',
              type: StatusType.warning,
              icon: Icons.cloud_off,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

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
                  FinancialMath.formatInr(portfolio.totalPortfolioValueInr),
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
                        value: FinancialMath.formatInr(portfolio.holdingsValueInr),
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
                  '${portfolio.holdings.length} positions',
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
            ...portfolio.holdings.map((h) => Padding(
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
  final Holding holding;

  const _HoldingCard({required this.holding});

  @override
  Widget build(BuildContext context) {
    final isProfit = holding.unrealisedPnlInr >= 0;
    final pnlColor = isProfit ? AppColors.successGreen : AppColors.errorRed;
    final initial = holding.symbol.length >= 2
        ? holding.symbol.substring(0, 2).toUpperCase()
        : holding.symbol.toUpperCase();

    return AppCard(
      hasBorder: true,
      onTap: () => context.push('/asset/${holding.symbol}'),
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
                      holding.symbol,
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
                        '${FinancialMath.formatInr(holding.unrealisedPnlInr.abs())} (${holding.unrealisedPnlPercent.abs().toStringAsFixed(2)}%)',
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
                onTap: () => context.push('/trade', extra: holding.symbol),
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
