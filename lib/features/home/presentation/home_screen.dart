import 'package:flutter/material.dart';
import 'package:cryptoedu/shared/widgets/crypto_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';
import '../../market/presentation/markets_screen.dart';
import '../../portfolio/presentation/portfolio_screen.dart';
import '../../trading/presentation/trade_entry_screen.dart';
import '../../../shared/widgets/trade_card.dart';
import 'app_shell.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider);
    final assetsAsync = ref.watch(supportedAssetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CryptoEdu Simulator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.star_border, color: AppColors.alert),
            onPressed: () => context.push('/paywall'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            portfolioAsync.when(
              data: (portfolio) => TradeCard(
                padding: const EdgeInsets.all(20),
                semanticLabel: 'Virtual portfolio performance',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Virtual Portfolio Equity',
                              style: TextStyle(color: AppColors.textSecondary)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.electricCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('SIMULATED ₹',
                                style: TextStyle(
                                    color: AppColors.electricCyan,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        FinancialMath.formatInr(
                            portfolio.totalPortfolioValueInr),
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                                fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Unrealised P&L',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              Text(
                                FinancialMath.formatInr(
                                    portfolio.totalUnrealisedPnlInr),
                                style: TextStyle(
                                  color: portfolio.totalUnrealisedPnlInr >= 0
                                      ? AppColors.profit
                                      : AppColors.loss,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Overall Return',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              Text(
                                '${portfolio.overallPnlPercent.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: portfolio.overallPnlPercent >= 0
                                      ? AppColors.profit
                                      : AppColors.loss,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                ),
              ),
              loading: () => const Center(child: CryptoLoadingIndicator()),
              error: (err, stack) => Text('Error loading wallet: $err'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TradeCard(
                    onTap: () => context.push('/discipline-meter'),
                    margin: EdgeInsets.zero,
                    child: const Column(
                      children: [
                        Icon(Icons.verified_outlined,
                            color: AppColors.alert, size: 28),
                        SizedBox(height: 8),
                        Text('Discipline Score',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        SizedBox(height: 4),
                        Text('85/100',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.alert)),
                        Text('High Process',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.profit)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TradeCard(
                    onTap: () => context.push('/risk-meter'),
                    margin: EdgeInsets.zero,
                    child: const Column(
                      children: [
                        Icon(Icons.speed_outlined,
                            color: AppColors.cyberGold, size: 28),
                        SizedBox(height: 8),
                        Text('Risk Score',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        SizedBox(height: 4),
                        Text('35/100',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.profit)),
                        Text('MODERATE',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.profit)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Supported V1 Markets',
                    style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => context.push('/markets'),
                  child: const Text('View All'),
                ),
              ],
            ),
            assetsAsync.when(
              data: (assets) => Column(
                children: assets.map((asset) {
                  return TradeCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.zero,
                    onTap: () => context.push('/trade/${asset.symbol}'),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.electricCyan.withValues(alpha: 0.2),
                        child: Text(asset.symbol[0],
                            style: const TextStyle(
                                color: AppColors.electricCyan,
                                fontWeight: FontWeight.bold)),
                      ),
                      title: Text(asset.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(asset.symbol),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(FinancialMath.formatInr(asset.currentPriceInr),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${asset.change24hPercent >= 0 ? '+' : ''}${asset.change24hPercent}%',
                            style: TextStyle(
                              color: asset.change24hPercent >= 0
                                  ? AppColors.profit
                                  : AppColors.loss,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              loading: () => const Center(child: CryptoLoadingIndicator()),
              error: (err, stack) => Text('Error loading markets: $err'),
            ),
          ],
        ),
      ),
    );
  }
}


