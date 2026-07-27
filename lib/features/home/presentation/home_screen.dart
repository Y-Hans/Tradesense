import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
            icon: const Icon(Icons.star_border, color: AppColors.discipline),
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
              data: (portfolio) => Card(
                color: AppColors.card,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Virtual Portfolio Equity', style: TextStyle(color: AppColors.textSecondary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('SIMULATED ₹', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        FinancialMath.formatInr(portfolio.totalPortfolioValueInr),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Unrealised P&L', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text(
                                FinancialMath.formatInr(portfolio.totalUnrealisedPnlInr),
                                style: TextStyle(
                                  color: portfolio.totalUnrealisedPnlInr >= 0 ? AppColors.profit : AppColors.loss,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Overall Return', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text(
                                '${portfolio.overallPnlPercent.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: portfolio.overallPnlPercent >= 0 ? AppColors.profit : AppColors.loss,
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
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading wallet: $err'),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/discipline-meter'),
                    child: const Card(
                      color: AppColors.card,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.verified_outlined, color: AppColors.discipline, size: 28),
                            SizedBox(height: 8),
                            Text('Discipline Score', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            SizedBox(height: 4),
                            Text('85/100', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.discipline)),
                            Text('High Process', style: TextStyle(fontSize: 10, color: AppColors.profit)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/risk-meter'),
                    child: const Card(
                      color: AppColors.card,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.speed_outlined, color: AppColors.accent, size: 28),
                            SizedBox(height: 8),
                            Text('Risk Score', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            SizedBox(height: 4),
                            Text('35/100', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.profit)),
                            Text('MODERATE', style: TextStyle(fontSize: 10, color: AppColors.profit)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Supported V1 Markets', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => context.push('/markets'),
                  child: const Text('View All'),
                ),
              ],
            ),

            assetsAsync.when(
              data: (assets) => Column(
                children: assets.map((asset) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(asset.symbol[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(asset.symbol),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(FinancialMath.formatInr(asset.currentPriceInr), style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${asset.change24hPercent >= 0 ? '+' : ''}${asset.change24hPercent}%',
                            style: TextStyle(
                              color: asset.change24hPercent >= 0 ? AppColors.profit : AppColors.loss,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => context.push('/trade/${asset.symbol}'),
                    ),
                  );
                }).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading markets: $err'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) context.push('/markets');
          if (index == 2) context.push('/portfolio');
          if (index == 3) context.push('/missions');
          if (index == 4) context.push('/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Markets'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Portfolio'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Missions'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
