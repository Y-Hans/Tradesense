import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../../../core/providers/app_providers.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Premium')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.workspace_premium,
                size: 72, color: AppColors.successGreen),
            const SizedBox(height: 16),
            Text('Unlock Deep AI Coaching',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            const Text(
              'Get unlimited trade explanations, advanced risk analytics, and exclusive beginner trading missions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen),
                onPressed: () async {
                  final sub = ref.read(subscriptionProvider);
                  await sub.purchasePremium();
                  if (context.mounted) context.pop();
                },
                child: const Text('UPGRADE NOW (REVENUECAT INTEGRATED)',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
