import 'package:cryptoedu/shared/widgets/bitcoin_loader.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';
import '../../../shared/models/crypto_asset.dart';


class MarketsScreen extends ConsumerWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(
      connectivityProvider.select(
          (status) => status == ConnectivityStatus.offline),
    );
    final assetsAsync = ref.watch(supportedAssetsProvider);

    return AppScaffold(
      showBackButton: false,
      title: 'Markets',
      trailing: isOffline
          ? const Icon(Icons.wifi_off, color: AppColors.warningOrange, size: 20)
          : null,
      body: isOffline
          ? const Center(
              child: Text(
                'Markets Offline\nCannot connect to live markets at this time.',
                textAlign: TextAlign.center,
              ),
            )
          : assetsAsync.when(
              data: (assets) => _buildMarketList(context, ref, assets),
              loading: () => const Center(
                child: AdaptiveLoader(),
              ),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Cannot connect to live markets at this time.'),
                    TextButton(
                      onPressed: () => ref.refresh(marketTickersProvider),
                      child: const Text('RETRY'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMarketList(
    BuildContext context,
    WidgetRef ref,
    List<CryptoAsset> assets,
  ) {
    return RefreshIndicator(
      color: AppColors.primaryCyan,
      backgroundColor: Theme.of(context).cardTheme.color,
      onRefresh: () async => ref.invalidate(supportedAssetsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: assets.length + 1, // +1 for header
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) return _buildHeader(context, assets);
          return _MarketTile(
            asset: assets[index - 1],
            onTap: () => context.push('/asset/${assets[index - 1].symbol}'),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<CryptoAsset> assets) {
    final gainers = assets.where((a) => a.change24hPercent > 0).length;
    final losers = assets.where((a) => a.change24hPercent < 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Market summary
        Row(
          children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up,
                        color: AppColors.successGreen, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$gainers Gainers',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.trending_down,
                        color: AppColors.errorRed, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$losers Losers',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.errorRed,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Column headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Asset',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              Text(
                'Price',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Text(
                '24h',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _MarketTile extends StatelessWidget {
  final CryptoAsset asset;
  final VoidCallback onTap;

  const _MarketTile({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUp = asset.change24hPercent >= 0;
    final changeColor = isUp ? AppColors.successGreen : AppColors.errorRed;
    final changeIcon = isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down;
    final initial = asset.symbol.length >= 2
        ? asset.symbol.substring(0, 2).toUpperCase()
        : asset.symbol.toUpperCase();

    return AppCard(
      hasBorder: true,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Asset avatar
          Container(
            width: 44,
            height: 44,
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

          // Name & symbol
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  asset.symbol,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),

          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                FinancialMath.formatInr(asset.currentPriceInr),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(changeIcon, color: changeColor, size: 16),
                  Text(
                    '${asset.change24hPercent.toStringAsFixed(2)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: changeColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: AppSpacing.sm),
          // Trade button
          GestureDetector(
            onTap: () => context.push('/trade', extra: asset.symbol),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: AppColors.primaryCyan.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'TRADE',
                style: TextStyle(
                  color: AppColors.primaryCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
