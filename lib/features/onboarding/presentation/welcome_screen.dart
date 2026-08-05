import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBackButton: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const AIAvatar(size: 64),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Become a\nbetter trader.',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      height: 1.2,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'TradeSense is your AI trading coach.\nJournal trades, detect mistakes, and improve discipline.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Get started',
                onPressed: () {
                  context.go('/disclaimer');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
