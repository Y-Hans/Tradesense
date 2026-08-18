import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/financial_math.dart';
import '../../../shared/models/crypto_asset.dart';

/// ───────────────────────────────────────────────
///  GROWW INSPIRED DASHBOARD ─────────────────────
///  Clean, simple, professional FinTech dashboard.
/// ───────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider);
    final assetsAsync = ref.watch(supportedAssetsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          onRefresh: () async {
            ref.invalidate(portfolioProvider);
            ref.invalidate(supportedAssetsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          userAsync.when(
                            data: (user) => Text(
                              'Hello, ${user?.displayName ?? 'Trader'}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            loading: () => SizedBox(
                                height: 24,
                                width: 100,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                            error: (_, __) => Text(
                              'Hello, Trader',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ready to trade today?',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              themeMode == AppThemeMode.light 
                                  ? Icons.light_mode_rounded 
                                  : (themeMode == AppThemeMode.dark ? Icons.dark_mode_rounded : Icons.star_rounded),
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: () {
                              final nextMode = AppThemeMode.values[(themeMode.index + 1) % AppThemeMode.values.length];
                              ref.read(themeModeProvider.notifier).state = nextMode;
                            },
                          ),
                          SizedBox(width: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_fire_department_rounded,
                                    color: AppColors.warning, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  '7 Days',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          IconButton(
                            icon: Icon(Icons.notifications_none_rounded,
                                color: Theme.of(context).colorScheme.onSurface),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Portfolio Summary Card ──────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: portfolioAsync.when(
                    data: (portfolio) => _PortfolioCard(portfolio: portfolio),
                    loading: () => _LoadingCard(),
                    error: (e, _) => _ErrorCard(error: e.toString()),
                  ),
                ),
              ),

              // ── Quick Access: Discipline & Risk ─────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ScorePill(
                          title: 'Discipline',
                          score: '85/100',
                          progress: 0.85,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _ScorePill(
                          title: 'Risk Score',
                          score: 'Safe',
                          progress: 0.92,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Live Market Watchlist ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Watchlist',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              
              assetsAsync.when(
                data: (assets) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _AssetRow(asset: assets[index]);
                      },
                      childCount: assets.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error loading assets: $e')),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  _PortfolioCard({required this.portfolio});

  final dynamic portfolio;

  @override
  Widget build(BuildContext context) {
    final totalValue = portfolio.totalPortfolioValueInr;
    final invested = portfolio.wallet.initialBalanceInr;
    final returns = (totalValue + portfolio.totalRealisedPnlInr) - invested;
    final returnsPercent = portfolio.overallPnlPercent;
    
    final isProfit = returns >= 0;
    final returnColor = isProfit ? AppColors.profit : Theme.of(context).colorScheme.error;
    final sign = isProfit ? '+' : '';

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).cardTheme.shape is RoundedRectangleBorder 
            ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).side.color 
            : Theme.of(context).dividerColor,
          width: Theme.of(context).cardTheme.shape is RoundedRectangleBorder 
            ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).side.width 
            : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Portfolio Value',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isProfit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: returnColor,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${returnsPercent.toStringAsFixed(2)}%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: returnColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            FinancialMath.formatInr(totalValue),
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PortfolioStat(
                label: 'Invested Value',
                value: FinancialMath.formatInr(invested),
              ),
              _PortfolioStat(
                label: 'Total Returns',
                value: '$sign${FinancialMath.formatInr(returns)}',
                valueColor: returnColor,
                crossAxisAlignment: CrossAxisAlignment.end,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioStat extends StatelessWidget {
  const _PortfolioStat({
    required this.label,
    required this.value,
    this.valueColor,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.title,
    required this.score,
    required this.progress,
    required this.color,
  });

  final String title;
  final String score;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelMedium),
              Text(
                score,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
              ),
            ],
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).cardTheme.color,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  _AssetRow({required this.asset});
  final CryptoAsset asset;

  @override
  Widget build(BuildContext context) {
    final isProfit = asset.change24hPercent >= 0;
    final color = isProfit ? AppColors.profit : Theme.of(context).colorScheme.error;
    final sign = isProfit ? '+' : '';

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Center(
                child: Text(
                  asset.symbol.substring(0, 1),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.symbol,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 2),
                  Text(
                    asset.name,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            // Minimal sparkline placeholder
            SizedBox(
              width: 60,
              height: 30,
              child: CustomPaint(
                painter: _SimpleSparklinePainter(color: color),
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FinancialMath.formatInr(asset.currentPriceInr),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 2),
                Text(
                  '$sign${asset.change24hPercent.toStringAsFixed(2)}%',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleSparklinePainter extends CustomPainter {
  final Color color;
  _SimpleSparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
        size.width * 0.25, size.height * 0.4, size.width * 0.5, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.8, size.width, size.height * 0.2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoadingCard extends StatelessWidget {
  _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  _ErrorCard({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.error),
      ),
      child: Center(
        child: Text(
          'Failed to load portfolio\n$error',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
