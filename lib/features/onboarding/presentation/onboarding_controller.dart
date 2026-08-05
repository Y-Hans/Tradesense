import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_state.dart';

part 'onboarding_controller.g.dart';

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(onboardingRepositoryProvider).completeOnboarding();
      state = state.copyWith(isLoading: false, isCompleted: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void saveProfile(String name, String style) {
    ref.read(onboardingRepositoryProvider).saveProfile(name, style);
  }

  void saveRisk(double lossLimit, String unit) {
    ref.read(onboardingRepositoryProvider).saveRisk(lossLimit, unit);
  }

  void setJournalPreference(bool manual) {
    ref.read(onboardingRepositoryProvider).setJournalPreference(manual: manual);
  }
}
