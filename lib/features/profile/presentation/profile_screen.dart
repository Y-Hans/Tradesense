import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';
import '../../../core/widgets/trade_card.dart';
import '../../../core/widgets/disclaimer_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Profile'),
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) {
          final displayName = user?.displayName ?? 'Discipline Trader';
          final email = user?.email ?? 'trader@cryptoedu.app';
          final balance = user?.virtualBalanceInr ?? 100000.0;

          // Level Title
          const String levelTitle = 'Risk-Aware Trader';
          const int xp = 250;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Header Card
                TradeCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'T',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
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

                const SizedBox(height: 16),

                // Discipline Tier & XP Badge Card
                TradeCard(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DISCIPLINE TIER',
                            style: TextStyle(
                              color: AppColors.discipline,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            levelTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '$xp XP',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Learning Features',
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
                    leading: const Icon(Icons.military_tech,
                        color: AppColors.discipline),
                    title: const Text('Missions & Rewards'),
                    subtitle:
                        const Text('Earn XP and boost your Discipline Tier'),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppColors.textSecondary),
                    onTap: () => context.push('/missions'),
                  ),
                ),

                const SizedBox(height: 12),
                
                // News Detective Tile
                TradeCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.search_rounded,
                        color: AppColors.primary),
                    title: const Text('News Detective 🕵️‍♂️'),
                    subtitle: const Text(
                        'Train source verification & spot clickbait'),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppColors.textSecondary),
                    onTap: () => context.push('/news-detective'),
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

                // Replay Onboarding
                TradeCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.replay_rounded,
                        color: AppColors.primary),
                    title: const Text('Replay Onboarding'),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppColors.textSecondary),
                    onTap: () => context.push('/onboarding'),
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
                    onTap: () => context.push('/paywall'),
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
                      if (context.mounted) context.go('/login');
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
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Account deletion requires platform infrastructure setup.',
                          ),
                        ),
                      );
                    },
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
