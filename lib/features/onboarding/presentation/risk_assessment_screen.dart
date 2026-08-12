import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'onboarding_controller.dart';

class RiskAssessmentScreen extends ConsumerStatefulWidget {
  const RiskAssessmentScreen({super.key});

  @override
  ConsumerState<RiskAssessmentScreen> createState() => _RiskAssessmentScreenState();
}

class _RiskAssessmentScreenState extends ConsumerState<RiskAssessmentScreen> {
  final _lossLimitController = TextEditingController();
  String _selectedUnit = '₹';

  @override
  void initState() {
    super.initState();
    _lossLimitController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _lossLimitController.removeListener(_onTextChanged);
    _lossLimitController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final limit = double.tryParse(_lossLimitController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    return limit != null && limit > 0;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Risk Guardrails',
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set your risk guardrails',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              _selectedUnit == '₹' 
                  ? 'TradeSense will alert you if your daily loss exceeds this amount.'
                  : 'TradeSense will alert you if your daily loss exceeds this percentage of your account.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppTextField(
              controller: _lossLimitController,
              labelText: 'Max daily loss',
              hintText: _selectedUnit == '₹' ? 'e.g. 5000' : 'e.g. 1.5',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Container(
                margin: EdgeInsets.only(right: AppSpacing.sm),
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedUnit,
                    dropdownColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                    icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey, size: 20),
                    items: ['₹', '%'].map((String unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(
                          unit,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.primaryCyan,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedUnit = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const Spacer(),
            PrimaryButton(
              text: 'Continue',
              onPressed: _isValid
                  ? () {
                      final limit = double.tryParse(_lossLimitController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                      ref.read(onboardingControllerProvider.notifier).saveRisk(limit, _selectedUnit);
                      context.go('/import-choice');
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
