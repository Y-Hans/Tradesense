import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);

    return AppScaffold(
      showBackButton: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Hero icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryCyan.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.primaryCyan.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    size: 52,
                    color: AppColors.primaryCyan,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Greeting
              userAsync.when(
                data: (user) => Text(
                  user != null
                      ? 'Welcome, ${user.displayName}!'
                      : 'Welcome to TradeSense!',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                loading: () => Text(
                  'Welcome to TradeSense!',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                error: (_, __) => Text(
                  'Welcome to TradeSense!',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Learn to trade crypto without financial risk.\nPractice with ₹1,00,000 in virtual funds.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Feature highlights
              _FeatureRow(
                icon: Icons.psychology_outlined,
                color: AppColors.primaryCyan,
                title: 'AI Trade Coach',
                description:
                    'Get personalised feedback after every virtual trade',
              ),
              const SizedBox(height: AppSpacing.md),
              _FeatureRow(
                icon: Icons.shield_outlined,
                color: AppColors.successGreen,
                title: 'Risk & Discipline Scores',
                description:
                    'Understand your trading behaviour with real-time analysis',
              ),
              const SizedBox(height: AppSpacing.md),
              _FeatureRow(
                icon: Icons.emoji_events_outlined,
                color: AppColors.warningOrange,
                title: 'Learning Missions',
                description:
                    'Complete challenges and earn XP to unlock new concepts',
              ),

              const Spacer(),

              // CTA — goes to profile setup
              PrimaryButton(
                text: 'Set Up Trading Profile',
                onPressed: () => context.go('/profile-setup'),
                icon: const Icon(Icons.arrow_forward),
              ),

              const SizedBox(height: AppSpacing.md),

              // Skip to home (if user knows what they're doing)
              SecondaryButton(
                text: 'Skip for now',
                onPressed: () => context.go('/'),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
