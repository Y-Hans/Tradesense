import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/disclaimer_card.dart';

class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  static const List<OnboardingStep> steps = [
    OnboardingStep(
      title: 'Practice Crypto Safely',
      description:
          'Practice crypto trading without risking real money in a risk-free educational environment.',
      icon: Icons.shield_outlined,
    ),
    OnboardingStep(
      title: '₹100,000 Virtual Starting Balance',
      description:
          'Start with ₹100,000 virtual funds and practise using real market prices in real-time.',
      icon: Icons.account_balance_wallet_outlined,
    ),
    OnboardingStep(
      title: 'Discipline Score & AI Insights',
      description:
          'Improve your Discipline Score and learn from AI feedback after simulated trades.',
      icon: Icons.psychology_outlined,
    ),
  ];
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastStep => _currentIndex == OnboardingStep.steps.length - 1;

  void _finishOnboarding() {
    if (context.mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    const steps = OnboardingStep.steps;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ONBOARDING',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (!_isLastStep)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: steps.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.15),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 2.0,
                            ),
                          ),
                          child: Icon(
                            step.icon,
                            size: 64.0,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 32.0),
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          step.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15.0,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                steps.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: _currentIndex == index ? 24.0 : 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppColors.primary
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: DisclaimerCard(compact: true),
            ),
            const SizedBox(height: 24.0),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50.0,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () {
                    if (_isLastStep) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    _isLastStep ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
