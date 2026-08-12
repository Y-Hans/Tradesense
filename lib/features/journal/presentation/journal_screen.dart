import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'journal_controller.dart';
import '../domain/journal_state.dart';

class JournalScreen extends ConsumerWidget {
  JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(journalControllerProvider);

    return AppScaffold(
      showBackButton: false,
      title: 'Journal',
      trailing: IconButton(
        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
        onPressed: () => context.push('/trade'),
      ),
      body: asyncState.when(
        data: (state) => _buildBody(context, ref, state),
        loading: () => Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
        ),
        error: (error, stack) => EmptyState(
          icon: Icons.error_outline,
          title: 'Error loading journal',
          description: error.toString(),
          primaryAction: PrimaryButton(
            text: 'Try again',
            onPressed: () => ref.read(journalControllerProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, JournalState state) {
    if (state.trades.isEmpty) {
      return EmptyState(
        icon: Icons.menu_book,
        title: 'Your journal is empty',
        description: 'Log your trades to receive AI coaching and pattern analysis.',
        primaryAction: PrimaryButton(
          text: 'Log first trade',
          onPressed: () => context.push('/trade'),
        ),
      );
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      onRefresh: () => ref.read(journalControllerProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.trades.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final trade = state.trades[index];
          final isPositive = trade.pnl >= 0;
          
          return AppCard(
            hasBorder: true,
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          trade.symbol,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatusChip(
                          label: trade.type,
                          type: StatusType.neutral,
                        ),
                        if (trade.aiReviewed) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(Icons.auto_awesome, color: AppColors.primaryCyan, size: 14),
                        ],
                      ],
                    ),
                    Text(
                      '${isPositive ? '+' : ''}\$${trade.pnl.abs().toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isPositive ? AppColors.successGreen : AppColors.errorRed,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: trade.tags.map((tag) => TagChip(label: tag)).toList(),
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(trade.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
