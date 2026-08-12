import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'onboarding_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  String _selectedStyle = 'Day trader';
  final _styles = ['Day trader', 'Swing trader', 'Scalper'];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profile',
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Let\'s personalize your coaching',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            SizedBox(height: AppSpacing.xxl),
            AppTextField(
              controller: _nameController,
              labelText: 'What should the AI call you?',
              hintText: 'Your name',
            ),
            SizedBox(height: AppSpacing.xl),
            Text(
              'Primary trading style',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                  ),
            ),
            SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: _styles.map((style) {
                return ChoiceChip(
                  label: Text(style),
                  selected: _selectedStyle == style,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedStyle = style;
                      });
                    }
                  },
                  backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                  selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _selectedStyle == style ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    side: BorderSide(
                      color: _selectedStyle == style ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            PrimaryButton(
              text: 'Continue',
              onPressed: _nameController.text.isNotEmpty
                  ? () {
                      ref.read(onboardingControllerProvider.notifier)
                          .saveProfile(_nameController.text, _selectedStyle);
                      context.go('/risk-assessment');
                    }
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
