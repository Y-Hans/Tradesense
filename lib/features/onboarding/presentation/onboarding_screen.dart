import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_outlined,
                  size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Learn Crypto Trading\nWithout Financial Risk',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Practice trading live markets with ₹100,000 virtual cash. Build trading discipline, master risk management, and receive personalized AI coaching.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('GET STARTED (RECEIVE ₹100,000)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
