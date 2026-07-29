import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';
import '../../../core/widgets/disclaimer_card.dart';
import '../../../core/widgets/trade_card.dart';
import '../domain/educational_disclosures.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _showDeleteAccountDialog(
      BuildContext context, WidgetRef ref) async {
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action will clear your session and account profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.loss),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !context.mounted) return;

    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'This is your final confirmation. Proceeding will permanently remove account data and sign you out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.loss),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );

    if (finalConfirm != true || !context.mounted) return;

    final success = await ref.read(authStateProvider.notifier).deleteAccount();
    if (success && context.mounted) {
      ref.read(userLifecycleProvider.notifier).reset();
      try {
        context.go('/login');
      } catch (_) {}
    } else if (context.mounted) {
      final errorMessage = ref.read(authStateProvider).errorMessage ??
          'Account deletion failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.loss,
        ),
      );
    }
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy & Educational Policy'),
        content: const SingleChildScrollView(
          child: Text(
            '${EducationalDisclosures.simulationNotice}\n\n'
            '${EducationalDisclosures.noRealCryptoNotice}\n\n'
            '${EducationalDisclosures.noGuaranteeNotice}\n\n'
            'TradeSense is strictly designed to build trading discipline and risk awareness.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: userAsync.when(
        data: (user) {
          final displayName = user?.displayName ?? 'Trader';
          final email = user?.email ?? 'trader@cryptoedu.app';
          final balance = user?.virtualBalanceInr ?? 100000.0;
          final joinedText = user != null
              ? 'Joined ${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
              : 'Active Session';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header Card (Somya Glassmorphic TradeCard styling)
                TradeCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'T',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              joinedText,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Starting Balance: ${FinancialMath.formatInr(balance)} SIMULATED',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.profit,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Discipline Tier Badge
                TradeCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DISCIPLINE TIER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Disciplined Trader',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.discipline,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.discipline.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  AppColors.discipline.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield,
                                size: 16, color: AppColors.discipline),
                            SizedBox(width: 4),
                            Text(
                              '85 / 100',
                              style: TextStyle(
                                color: AppColors.discipline,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Learning & Features',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Missions Tile
                TradeCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.stars, color: AppColors.accent),
                    title: const Text('Missions & Rewards'),
                    subtitle: const Text('Earn XP and level up discipline'),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppColors.textSecondary),
                    onTap: () {
                      try {
                        context.push('/missions');
                      } catch (_) {}
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // News Detective Tile
                TradeCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.manage_search,
                        color: AppColors.primary),
                    title: const Text('News Detective Quiz'),
                    subtitle: const Text(
                        'Train source verification & spot clickbait'),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppColors.textSecondary),
                    onTap: () {
                      try {
                        context.push('/news-detective');
                      } catch (_) {}
                    },
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Settings & Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Privacy & Disclaimers
                TradeCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined,
                        color: AppColors.primary),
                    title: const Text('Privacy & Disclaimers'),
                    subtitle:
                        const Text('Educational policy & simulation rules'),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppColors.textSecondary),
                    onTap: () => _showPrivacyDialog(context),
                  ),
                ),

                const SizedBox(height: 12),

                // Subscription Status
                TradeCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading:
                        const Icon(Icons.star, color: AppColors.discipline),
                    title: const Text('Subscription Status'),
                    trailing: Text(
                      user?.isPremium == true ? 'PREMIUM' : 'FREE',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      try {
                        context.push('/paywall');
                      } catch (_) {}
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Sign Out
                TradeCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading:
                        const Icon(Icons.logout, color: AppColors.textPrimary),
                    title: const Text('Sign Out'),
                    onTap: () async {
                      await ref.read(authStateProvider.notifier).signOut();
                      if (context.mounted) {
                        try {
                          context.go('/login');
                        } catch (_) {}
                      }
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Delete Account
                TradeCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: AppColors.loss),
                    title: const Text(
                      'Delete Account & Private Data',
                      style: TextStyle(color: AppColors.loss),
                    ),
                    onTap: () => _showDeleteAccountDialog(context, ref),
                  ),
                ),

                const SizedBox(height: 24),

                // Educational Disclaimer Card
                const DisclaimerCard(compact: false),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Text('Error: $err'),
      ),
    );
  }
}
