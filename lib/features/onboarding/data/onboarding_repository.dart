// ignore_for_file: unused_field
import 'package:riverpod_annotation/riverpod_annotation.dart';


part 'onboarding_repository.g.dart';

class OnboardingRepository {
  bool _hasCompletedOnboarding = false;
  String? _userName;
  String? _tradeStyle;
  double? _dailyLossLimit;
  String _lossLimitUnit = '₹';
  bool _useManualJournal = true;

  String? get userName => _userName;

  Future<void> completeOnboarding() async {
    // Simulate network/storage delay
    await Future.delayed(const Duration(milliseconds: 500));
    _hasCompletedOnboarding = true;
  }

  Future<bool> checkOnboardingStatus() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _hasCompletedOnboarding;
  }

  void saveProfile(String name, String style) {
    _userName = name;
    _tradeStyle = style;
  }

  void saveRisk(double lossLimit, String unit) {
    _dailyLossLimit = lossLimit;
    _lossLimitUnit = unit;
  }

  void setJournalPreference({required bool manual}) {
    _useManualJournal = manual;
  }
}

@riverpod
OnboardingRepository onboardingRepository(OnboardingRepositoryRef ref) {
  return OnboardingRepository();
}
