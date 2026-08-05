import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Disclaimer',
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warningOrange,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Important Disclaimer',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'TradeSense is an educational and coaching tool. It is NOT a brokerage and does not provide financial advice.\n\nAll trading involves risk. You are solely responsible for your own trading decisions.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
            const Spacer(),
            SecondaryButton(
              text: 'Review full terms',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).cardColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.7,
                    maxChildSize: 0.9,
                    minChildSize: 0.5,
                    expand: false,
                    builder: (context, scrollController) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: ListView(
                        controller: scrollController,
                        children: [
                          Text(
                            'Terms of Service & Disclosures',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '1. Educational Nature: TradeSense is strictly an educational crypto trading simulator. No real money or actual cryptocurrency is involved.\n\n'
                            '2. No Financial Advice: AI Coach suggestions, discipline metrics, and risk scores are produced by deterministic scoring formulas and LLM models for learning purposes only. They do not constitute investment advice.\n\n'
                            '3. Virtual Capital: The ₹10,000,000 virtual balance provided is simulated capital with zero real monetary value.\n\n'
                            '4. Privacy: User data and trading statistics are stored securely to provide personalized discipline coaching.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          PrimaryButton(
                            text: 'Close',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              text: 'I understand',
              onPressed: () {
                context.go('/profile-setup');
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
