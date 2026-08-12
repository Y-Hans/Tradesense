import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'onboarding_controller.dart';
import 'package:go_router/go_router.dart';

class ImportChoiceScreen extends ConsumerWidget {
  const ImportChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    
    // Listen for completion
    ref.listen(onboardingControllerProvider, (previous, next) {
      if (next.isCompleted) {
        context.go('/home');
      }
    });

    return AppScaffold(
      showBackButton: false,
      body: EmptyState(
        customGraphic: Container(
          width: 120,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Center(
            child: Icon(
              Icons.book,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        title: 'Start your trading journal',
        description: 'Log your first trade so TradeSense can begin detecting patterns and coaching your decisions.',
        primaryAction: PrimaryButton(
          text: 'Log first trade',
          isLoading: state.isLoading,
          onPressed: () {
            ref.read(onboardingControllerProvider.notifier).setJournalPreference(true);
            ref.read(onboardingControllerProvider.notifier).completeOnboarding();
          },
        ),
      ),
    );
  }
}
