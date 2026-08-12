import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/financial_math.dart';
import '../../../app/theme/theme_provider.dart';
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
            child: const Text('Confirm Deletion'),
          ),
        ],
      ),
    );

    if (finalConfirm != true || !context.mounted) return;

    final success = await ref.read(authStateProvider.notifier).deleteAccount();
    if (!success && context.mounted) {
      final authState = ref.read(authStateProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage ?? 'Account deletion failed.'),
        ),
      );
    }
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy & Disclosures'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                EducationalDisclosures.simulationNotice,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(EducationalDisclosures.noRealCryptoNotice),
              SizedBox(height: 8),
              Text(EducationalDisclosures.noGuaranteeNotice),
              SizedBox(height: 8),
              Text(EducationalDisclosures.zeroFinancialRiskNotice),
              SizedBox(height: 8),
              Text(
                EducationalDisclosures.regulatoryDisclaimer,
                style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
              ),
            ],
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
        title: const Text('Account & Profile'),
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) {
          final displayName = user?.displayName ?? 'Discipline Trader';
          final email = user?.email ?? 'trader@cryptoedu.app';
          final balance = user?.virtualBalanceInr ?? 100000.0;
          final joinedText = user != null
              ? 'Joined: ${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
              : 'Status: Authenticated';

          // Level Title
          const String levelTitle = 'Risk-Aware Trader';
          const int xp = 250;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Header Card
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
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
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                joinedText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
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
                ),

                SizedBox(height: 16),

                // Discipline Tier & XP Badge Card
                Card(
                  color: Theme.of(context).cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DISCIPLINE TIER',
                                style: TextStyle(
                                  color: AppColors.discipline,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                levelTitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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
                ),

                SizedBox(height: 20),

                Text(
                  'Learning Features',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Missions Tile
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.military_tech,
                        color: AppColors.discipline),
                    title: const Text('Missions & Rewards'),
                    subtitle:
                        Text('Earn XP and boost your Discipline Tier'),
                    trailing: Icon(Icons.arrow_forward_ios,
                        size: 16, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                    onTap: () => context.push('/missions'),
                  ),
                ),

                // News Detective Tile
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.search_rounded,
                        color: AppColors.primary),
                    title: const Text('News Detective 🕵️‍♂️'),
                    subtitle: Text(
                        'Train source verification & spot clickbait'),
                    trailing: Icon(Icons.arrow_forward_ios,
                        size: 16, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                    onTap: () => context.push('/news-detective'),
                  ),
                ),

                SizedBox(height: 20),

                Text(
                  'Settings & Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Appearance Settings
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.brightness_6, color: AppColors.primary),
                            SizedBox(width: 16),
                            Text('Appearance', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        DropdownButton<ThemeMode>(
                          value: ref.watch(themeModeProvider),
                          underline: const SizedBox.shrink(),
                          onChanged: (ThemeMode? newMode) {
                            if (newMode != null) {
                              ref.read(themeModeProvider.notifier).setThemeMode(newMode);
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('System'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Light'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Dark'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Privacy & Disclaimers
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined,
                        color: AppColors.primary),
                    title: const Text('Privacy & Disclaimers'),
                    subtitle:
                        Text('Educational policy & simulation rules'),
                    trailing: Icon(Icons.arrow_forward_ios,
                        size: 16, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                    onTap: () => _showPrivacyDialog(context),
                  ),
                ),

                // Subscription Status
                Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.star, color: AppColors.discipline),
                    title: const Text('Subscription Status'),
                    trailing: Text(
                      user?.isPremium == true ? 'PREMIUM' : 'FREE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => context.push('/paywall'),
                  ),
                ),

                // Sign Out
                Card(
                  child: ListTile(
                    leading:
                        Icon(Icons.logout, color: Theme.of(context).colorScheme.onSurface),
                    title: const Text('Sign Out'),
                    onTap: () async {
                      await ref.read(authStateProvider.notifier).signOut();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ),

                // Delete Account
                Card(
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
                Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Educational Simulation Notice',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${EducationalDisclosures.simulationNotice} ${EducationalDisclosures.noRealCryptoNotice}',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
