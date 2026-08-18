import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';
import '../../../shared/models/crypto_asset.dart';
import '../../../shared/models/portfolio.dart';
import '../../../shared/models/trade.dart';
import '../../../shared/models/user_profile.dart';
import '../../intelligence/providers/score_providers.dart';
import '../../learning/application/learning_progression_notifier.dart';
import 'today_controller.dart';
import '../domain/today_state.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(todayControllerProvider);
    final userAsync = ref.watch(currentUserProvider);
    final portfolioAsync = ref.watch(portfolioProvider);
    final assetsAsync = ref.watch(supportedAssetsProvider);
    final scoreAsync = ref.watch(portfolioScoresProvider);

    return AppScaffold(
      showBackButton: false,
      trailing: IconButton(
        icon: Icon(Icons.notifications_none),
        // Integration Point (Divyanshu): Real-time push notifications require
        // the native notification module from the platform team.
        onPressed: () => _showNotificationsSheet(context),
        tooltip: 'Notifications',
      ),
      body: RefreshIndicator(
        color: AppColors.primaryCyan,
        backgroundColor: Theme.of(context).cardTheme.color,
        onRefresh: () => ref.read(todayControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xxxl,
          ),
          children: [
            const SizedBox(height: AppSpacing.lg),

            // ── Greeting ──────────────────────────────────────────────────
            _GreetingSection(userAsync: userAsync),
            const SizedBox(height: AppSpacing.xxl),

            // ── AI Daily Brief ────────────────────────────────────────────
            asyncState.when(
              data: (state) => _AIDailyBrief(state: state),
              loading: () => const AIInsightCard(
                title: 'AI Daily Brief',
                content: '',
                isLoading: true,
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Portfolio Snapshot ────────────────────────────────────────
            _SectionHeader(
              title: 'Portfolio',
              action: 'View all',
              onAction: () => context.go('/portfolio'),
            ),
            const SizedBox(height: AppSpacing.md),
            _PortfolioSnapshot(portfolioAsync: portfolioAsync),
            const SizedBox(height: AppSpacing.xxl),

            // ── Discipline & Risk Scores ──────────────────────────────────
            _SectionHeader(title: 'Trading Performance'),
            const SizedBox(height: AppSpacing.md),
            _ScoreCards(scoreAsync: scoreAsync),
            const SizedBox(height: AppSpacing.xxl),

            // ── Market Overview ───────────────────────────────────────────
            _SectionHeader(
              title: 'Markets',
              action: 'All markets',
              onAction: () => context.go('/markets'),
            ),
            const SizedBox(height: AppSpacing.md),
            _MarketOverview(assetsAsync: assetsAsync),
            const SizedBox(height: AppSpacing.xxl),

            // ── Missions Progress ─────────────────────────────────────────
            _SectionHeader(
              title: 'Missions',
              action: 'View all',
              onAction: () => context.go('/missions'),
            ),
            const SizedBox(height: AppSpacing.md),
            const _MissionsProgress(),
            const SizedBox(height: AppSpacing.xxl),

            // ── Recent Activity ───────────────────────────────────────────
            _SectionHeader(
              title: 'Recent Activity',
              action: 'History',
              onAction: () => context.push('/trade-history'),
            ),
            const SizedBox(height: AppSpacing.md),
            const _RecentActivity(),
            const SizedBox(height: AppSpacing.xxl),

            // ── Quick Actions ─────────────────────────────────────────────
            _SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: AppSpacing.md),
            _QuickActions(),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            const EmptyState(
              icon: Icons.notifications_none,
              title: 'No new notifications',
              description:
                  'You\'re all caught up. Coaching alerts will appear here after each trade.',
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ── Greeting Section ─────────────────────────────────────────────────────────

class _GreetingSection extends StatelessWidget {
  final AsyncValue<UserProfile?> userAsync;

  const _GreetingSection({required this.userAsync});

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getSubtitle() {
    final hour = DateTime.now().hour;
    if (hour < 9) return 'Early bird! Markets open at 9:15 AM IST.';
    if (hour < 15) return 'Markets are live. Trade with discipline today.';
    if (hour < 16) return 'Market close approaching. Review your positions.';
    return 'Markets closed. Review today\'s performance.';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingText();

    return userAsync.when(
      data: (user) {
        final name =
            (user?.displayName.isNotEmpty == true) ? user!.displayName : 'Trader';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $name 👋',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              _getSubtitle(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                  ),
            ),
          ],
        );
      },
      loading: () => Text(
        '$greeting 👋',
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      error: (_, __) => Text(
        '$greeting 👋',
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

// ── AI Daily Brief ────────────────────────────────────────────────────────────

class _AIDailyBrief extends StatelessWidget {
  final TodayState state;

  const _AIDailyBrief({required this.state});

  @override
  Widget build(BuildContext context) {
    final title = state.coachInsightTitle ?? 'AI Daily Brief';
    final content = state.coachInsightContent ??
        'Risk management is today\'s focus. Remember: preserving capital always comes before chasing returns. Use stop-loss orders on every position.';

    return AIInsightCard(
      title: title,
      content: content,
      isLoading: state.isLoading && state.coachInsightContent == null,
    );
  }
}

// ── Portfolio Snapshot ────────────────────────────────────────────────────────

class _PortfolioSnapshot extends StatelessWidget {
  final AsyncValue<Portfolio> portfolioAsync;

  const _PortfolioSnapshot({required this.portfolioAsync});

  @override
  Widget build(BuildContext context) {
    return portfolioAsync.when(
      data: (portfolio) {
        final totalValue = portfolio.totalPortfolioValueInr;
        final unrealisedPnl = portfolio.totalUnrealisedPnlInr;
        final isProfit = unrealisedPnl >= 0;
        final pnlColor = isProfit ? AppColors.successGreen : AppColors.errorRed;

        return AppCard(
          hasBorder: true,
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Portfolio Value',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                    ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                FinancialMath.formatInr(totalValue),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    isProfit ? Icons.trending_up : Icons.trending_down,
                    color: pnlColor,
                    size: 18,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    '${isProfit ? '+' : ''}${FinancialMath.formatInr(unrealisedPnl)} unrealised',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: pnlColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _PortfolioStat(
                      label: 'Cash',
                      value: FinancialMath.formatInr(
                          portfolio.wallet.availableBalanceInr),
                    ),
                  ),
                  Expanded(
                    child: _PortfolioStat(
                      label: 'Holdings',
                      value: FinancialMath.formatInr(portfolio.holdingsValueInr),
                    ),
                  ),
                  Expanded(
                    child: _PortfolioStat(
                      label: 'Positions',
                      value: portfolio.holdings.length.toString(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => AppCard(
        hasBorder: true,
        padding: EdgeInsets.all(AppSpacing.lg),
        child: SizedBox(
          height: 80,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryCyan),
          ),
        ),
      ),
      error: (_, __) => AppCard(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Unable to load portfolio data.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
              ),
        ),
      ),
    );
  }
}

class _PortfolioStat extends StatelessWidget {
  final String label;
  final String value;

  _PortfolioStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
              ),
        ),
        SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

// ── Score Cards ───────────────────────────────────────────────────────────────

class _ScoreCards extends StatelessWidget {
  final AsyncValue<PortfolioScores> scoreAsync;

  const _ScoreCards({required this.scoreAsync});

  @override
  Widget build(BuildContext context) {
    return scoreAsync.when(
      data: (scores) => Row(
        children: [
          Expanded(
            child: _ScoreCard(
              label: 'Discipline',
              score: scores.disciplineScore,
              color: AppColors.successGreen,
              icon: Icons.psychology_outlined,
              description: scores.disciplineLabel,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _ScoreCard(
              label: 'Risk',
              score: scores.riskScore,
              color: _riskColor(scores.riskScore),
              icon: Icons.shield_outlined,
              description: scores.riskLabel,
            ),
          ),
        ],
      ),
      loading: () => Row(
        children: [
          Expanded(
            child: AppCard(
              hasBorder: true,
              padding: EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primaryCyan),
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppCard(
              hasBorder: true,
              padding: EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primaryCyan),
                ),
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Color _riskColor(int score) {
    if (score < 30) return AppColors.successGreen;
    if (score < 60) return AppColors.warningOrange;
    return AppColors.errorRed;
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  final IconData icon;
  final String description;

  const _ScoreCard({
    required this.label,
    required this.score,
    required this.color,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasBorder: true,
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                    ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ScoreRing(score: score, size: 56, color: color),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                        height: 1.3,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Market Overview ───────────────────────────────────────────────────────────

class _MarketOverview extends StatelessWidget {
  final AsyncValue<List<CryptoAsset>> assetsAsync;

  const _MarketOverview({required this.assetsAsync});

  @override
  Widget build(BuildContext context) {
    return assetsAsync.when(
      data: (assets) {
        final top = assets.take(3).toList();
        return Column(
          children: top.map((asset) {
            final isUp = asset.change24hPercent >= 0;
            final changeColor =
                isUp ? AppColors.successGreen : AppColors.errorRed;
            final initial =
                asset.symbol.length >= 2 ? asset.symbol.substring(0, 2) : asset.symbol;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                hasBorder: true,
                onTap: () => context.push('/asset/${asset.symbol}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
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
                          initial.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            asset.symbol,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          FinancialMath.formatInr(asset.currentPriceInr),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUp
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: changeColor,
                              size: 18,
                            ),
                            Text(
                              '${asset.change24hPercent.toStringAsFixed(2)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: changeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(color: AppColors.primaryCyan),
        ),
      ),
      error: (_, __) => AppCard(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: EmptyState(
          icon: Icons.wifi_off,
          title: 'Markets unavailable',
          description: 'Check your connection to see live prices.',
        ),
      ),
    );
  }
}

// ── Missions Progress ─────────────────────────────────────────────────────────

class _MissionsProgress extends ConsumerWidget {
  const _MissionsProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressionState = ref.watch(learningProgressionNotifierProvider);
    final completedCount = progressionState.completedMissionIds.length;
    final totalCount = progressionState.missions.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    final hasStarted = completedCount > 0;

    return AppCard(
      hasBorder: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: AppColors.warningOrange,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '$completedCount/$totalCount missions completed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              StatusChip(
                label: hasStarted ? 'In Progress' : 'Not Started',
                type: hasStarted ? StatusType.warning : StatusType.neutral,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.warningOrange,
              ),
              minHeight: 8,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            hasStarted
                ? '🏆 $completedCount completed! Keep completing missions to earn XP and level up.'
                : '📋 Complete educational missions to level up your discipline.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Recent Activity ───────────────────────────────────────────────────────────

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradingRepo = ref.watch(tradingRepositoryProvider);

    return FutureBuilder<List<Trade>>(
      future: tradingRepo.getTradeHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final trades = (snapshot.data ?? []).take(3).toList();

        if (trades.isEmpty) {
          return AppCard(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: EmptyState(
              icon: Icons.history,
              title: 'No trades yet',
              description:
                  'Your recent trades will appear here. Go to Markets to place your first trade.',
            ),
          );
        }

        return Column(
          children: trades.map((trade) {
            final isBuy = trade.side == TradeSide.buy;
            final color = isBuy ? AppColors.successGreen : AppColors.errorRed;
            final typeLabel = isBuy ? 'BUY' : 'SELL';

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                hasBorder: true,
                onTap: () => context.push('/coach-result/${trade.id}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        isBuy ? Icons.arrow_upward : Icons.arrow_downward,
                        color: color,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$typeLabel ${trade.symbol}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${trade.quantity.toStringAsFixed(4)} · ${FinancialMath.formatInr(trade.executionPriceInr)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          FinancialMath.formatInr(trade.totalAmountInr),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        const StatusChip(
                          label: 'AI review',
                          type: StatusType.neutral,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.show_chart,
            label: 'Trade',
            color: AppColors.primaryCyan,
            onTap: () => context.push('/trade', extra: 'BTCUSDT'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Portfolio',
            color: AppColors.successGreen,
            onTap: () => context.go('/portfolio'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.history,
            label: 'History',
            color: AppColors.secondaryPurple,
            onTap: () => context.push('/trade-history'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.menu_book_outlined,
            label: 'Journal',
            color: AppColors.warningOrange,
            onTap: () => context.push('/journal'),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        hasBorder: true,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  _SectionHeader({
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (action != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryCyan,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }
}
