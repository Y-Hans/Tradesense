import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../shared/models/user_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return AppScaffold(
      showBackButton: false,
      title: 'Profile',
      body: userAsync.when(
        data: (user) => _buildProfile(context, ref, user, isDark),
        loading: () => Center(
          child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary),
        ),
        error: (err, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Error loading profile',
          description: 'Unable to load account information.',
          primaryAction: PrimaryButton(
            text: 'Retry',
            onPressed: () => ref.invalidate(currentUserProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    WidgetRef ref,
    UserProfile? user,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    const secondaryTextColor = AppColors.textSecondary;
    final name =
        (user?.displayName.isNotEmpty == true) ? user!.displayName : 'Trader';
    final email = user?.email ?? '—';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── User Info Header ─────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              const AIAvatar(size: 80),
              const SizedBox(height: AppSpacing.md),
              Text(
                name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const StatusChip(
                label: 'Simulator Account',
                type: StatusType.neutral,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // ── Preferences Section ──────────────────────────────────────────
        Text('Preferences', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                title: Text(
                  'Dark Mode',
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  'Toggle appearance theme',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryTextColor),
                ),
                activeThumbColor: AppColors.primaryCyan,
                value: isDark,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).toggleTheme(val);
                },
              ),
              const Divider(height: 1),
              // Integration Point (Divyanshu — Platform Module):
              // Real push notification permission requires OS-level permission
              // flow via the native notifications module.
              // Showing status label instead of a fake permission dialog.
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(
                  'Push Notifications',
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  'Requires platform notification module — contact Divyanshu',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: secondaryTextColor),
                ),
                trailing: const StatusChip(
                  label: 'Pending',
                  type: StatusType.warning,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // ── Account Info ─────────────────────────────────────────────────
        Text('Account', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _InfoRow(label: 'Account type', value: 'Educational Simulator'),
              const Divider(height: AppSpacing.xl),
              _InfoRow(label: 'Currency', value: 'INR (₹) — Fixed Precision'),
              const Divider(height: AppSpacing.xl),
              _InfoRow(label: 'Starting balance', value: '₹1,00,000 virtual'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // ── Support Section ──────────────────────────────────────────────
        Text('Support', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title:
                    Text('Help & Support', style: theme.textTheme.titleMedium),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
                onTap: () => _showHelpSheet(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title:
                    Text('Privacy Policy', style: theme.textTheme.titleMedium),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
                onTap: () => _showPrivacySheet(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text('About TradeSense',
                    style: theme.textTheme.titleMedium),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // ── Sign Out ─────────────────────────────────────────────────────
        SecondaryButton(
          text: 'Sign Out',
          onPressed: () => _confirmSignOut(context, ref),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? Your virtual portfolio and trade history will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).signOut();
      // Invalidate user state so the app reflects the signed-out status
      ref.invalidate(currentUserProvider);
      // RouterListenable will handle redirecting to /splash automatically
      // But we can keep context.go just in case it's missed, or remove it.
      // Let's rely on RouterListenable.
    }
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Help & Support',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Need assistance or have feedback on TradeSense AI Coaching?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Contact Support'),
              subtitle: const Text('support@tradesense.app'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Trading Guides & FAQ'),
              subtitle: const Text('Learn about risk score calculation'),
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Text(
              'TradeSense respects your privacy. All trading data, discipline scores, and journal entries are securely processed and protected. We do not sell or share personal data with third-party brokers.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'Close',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('TradeSense'),
        content: const Text(
          'Version 1.0.0-beta\n\nAn educational crypto trading simulator with AI coaching. Trade virtual funds, build discipline, and learn risk management.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
