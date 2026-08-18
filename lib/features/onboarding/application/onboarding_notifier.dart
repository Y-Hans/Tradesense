import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_preferences.dart';

class OnboardingNotifier extends StateNotifier<void> {
  OnboardingNotifier() : super(null);

  /// Returns whether onboarding is completed for the specified user ID.
  bool isCompleted(String? userId) {
    if (userId == null) return false;
    return AppPreferences.isUserOnboardingCompleted(userId);
  }

  /// Marks onboarding as completed for the given user ID.
  Future<void> completeOnboarding(String userId) async {
    await AppPreferences.setUserOnboardingCompleted(userId, true);
    // Notify listeners so router can redirect
    state = null;
  }
}
